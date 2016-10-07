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
debug = require('debug')('yang:express') if process.env.DEBUG?
config = require 'config'
express = require 'express'

module.exports = require('../yang-express.yang').bind {

  # to use existing instance of express, you can .bind with an existing app
  '[express]': -> @content ?= express()
  '[restjson]':  require('./feature/restjson')
  '[openapi]':   require('./feature/openapi')
  '[websocket]': require('./feature/websocket')

  '/server/hostname': -> @content ?= require('os').hostname()

  run: ->
    app = @engine.express
    @input.feature ?= [ 'restjson' ]
    @in('/server').merge
      port: @input.port
      hostname: @input.hostname
      features: @input.feature
    @enable feature for feature in @input.feature
    @input.modules.forEach (name) =>
      debug? "[run] import/route '#{name}'"
      try m = @access name
      catch
        try m = @schema.constructor.import(name).eval(config)
        catch e
          console.error e
          throw new Error "unable to import '#{name}' YANG module, check your local 'package.json' for models"
      @in('/server/router').create name: m.name
    server = @get('/server')
    unless server.router?.length
      throw new Error "cannot run without any modules to route"
    @output = new Promise (resolve, reject) ->
      http = app.listen server.port
      http.on 'listening', ->
        app.emit 'listening', http
        resolve server
}
