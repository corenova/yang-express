/* 
YANG-EXPRESS (web server) middleware router module
This YANG model-driven module enables dynamic web server middleware
interface generation such as [restjson](restjson.coffee) and
[openapi](openapi.coffee).

It utilizes the [express](http://expressjs.com) web server framework
to dynamically instanticate the web server and makes itself
available for higher-order features to utilize it for associating
additional routing endpoints.
*/

const Yang = require('yang-js');

module.exports = require('./yang-express.yang').bind({

  '[express]':     require('express'),
  '[router]':      require('express').Router,
  '[body-parser]': require('body-parser'),
  '[restjson]':    require('./lib/restjson'),
  '[openapi]':     require('./lib/openapi'),

  server: {
    hostname() {
      const os = this.use('os')
      return os.hostname()
    }
  },

  listen(input) {
    const express = this.use('express')
    const { app=express() } = input
    const server = this.get('/server')
    const { routers=[], port } = server
    const discover = (req, res, next) => {
      // dynamically fetch leaf-list of modules on every request
      const modules = [].concat(this.get('/server/modules')).filter(Boolean)
      res.locals.modules = modules
      for (let name of modules) {
        const model = this.access(name)
        const match = model.in(req.path)
        if (match) {
          this.debug(`discover: found '${name}' model for ${req.path}`)
          res.locals = { model, match }
          break;
        }
      }
      next()
    }

    app.use(discover)
    for (let routerName of routers) {
      const router = this.use(routerName)
      if (!router) continue
      app.use(router.call(this))
      app.enable(routerName)
      this.debug(`enabled ${routerName} router`)
    }
    app.set('json spaces', 2)
    return {
      instance: app.listen(port)
    }
  }
})
