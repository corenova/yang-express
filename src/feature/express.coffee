# Express (web server) interface feature module
#
# This feature add-on module enables dynamic web server interface
# generation and is used as a `component` of other feature interfaces
# such as [restjson](restjson.litcoffee) and
# [autodoc](autodoc.litcoffee).
#
# It utilizes the [express](http://expressjs.com) web server framework
# to dynamically instanticate the web server and makes itself available
# for higher-order features to utilize it for associating additional routing endpoints.
#debug   = require('debug')('yang:express')
express = require 'express'

module.exports = (app=express()) ->
  (->
    # overload existing .listen to propagate 'listening' event
    # TODO: if express is "mounted" as a subapp, need to handled the "mount" event
    @listen = ((app, args...) ->
      # setup default error handler
      app.use (err, req, res, next) ->
        console.error err.stack
        res.status(500).send(error: message: err.message)
      server = @apply app, args
      server.on 'listening', -> app.emit 'listening', server
      return server
    ).bind @listen, this
    # provide a new 'mount' feature to register a new Router
    @mount = (f) =>
      router = f.call express.Router()
      @use router
      return router
    return this
  ).call app
