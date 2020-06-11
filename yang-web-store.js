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

require('yang-js');

module.exports = require('./yang-web-store.yang').bind({

  'feature(express)':     require('express'),
  'feature(body-parser)': require('body-parser'),
  'feature(multipart)':   require('multer'),
  'feature(discover)':    require('./lib/discover'),
  'feature(restjson)':    require('./lib/restjson'),
  'feature(openapi)':     require('./lib/openapi'),

  '/server/hostname': {
    get: (ctx) => ctx.use('os').hostname()
  },

  'rpc(listen)': (ctx, input) => {
    const express = ctx.use('express');
    const discover = ctx.use('discover');
    const { app=express() } = input;
    const server = ctx.get('/server');
    const { routers=[], modules=[], port } = server;
    ctx.logInfo(`listen on ${port} with %o routers for %o modules`, routers, modules);
    
    app.use(discover({ modules, store: ctx.store }));
    for (let routerName of routers) {
      const router = ctx.use(routerName);
      if (!router) continue
      app.use(router());
      app.enable(routerName);
      ctx.logDebug(`enabled ${routerName} router`)
    }
    app.set('json spaces', 2)
    return {
      instance: app.listen(port)
    }
  }
})
