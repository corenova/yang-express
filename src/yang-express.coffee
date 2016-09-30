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

  # to use existing instance of express, you can .bind with an existing app
  '[express]': -> @content ?= express()
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
      http = app.listen server.port
      http.on 'listening', ->
        app.emit 'listening', http
        resolve server
}
