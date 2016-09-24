# YANG-EXPRESS (web server) middleware router module
#
# This YANG model-driven module enables dynamic web server middleware
# interface generation such as [restjson](restjson.coffee) and
# [openapi](openapi.coffee).
#
# It utilizes the [express](http://expressjs.com) web server framework
# to dynamically instanticate the web server and makes itself
# available for higher-order features to utilize it for associating
# additional routing endpoints.
 
require 'yang-js'
express = require 'express'

module.exports = require('../schema/yang-express.yang').bind {

  # to use existing instance of express, you can model.enable 'express', <existing app>
  '[express]': ->
    @content ?= (->
      # overload existing listen() should consider alternative options
      @listen = ((app, args...) ->
        server = @apply app, args
        server.on 'listening', -> app.emit 'listening', server
        return server
      ).bind @listen, this
      return this
    ).call express()

  '[restjson]':  require('./feature/restjson')
  '[openapi]':   require('./feature/openapi')
  '[websocket]': require('./feature/websocket')

  '/server/hostname': -> @content ?= require('os').hostname()

  run: ->
    app = @engine.express
    server = @get('/server')
    server.port = @input.port
    server.hostname = @input.hostname
    @output = new Promise (resolve, reject) ->
      app.listen server.port
      app.on 'listening', -> resolve server
        
}
