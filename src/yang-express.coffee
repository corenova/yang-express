require 'yang-js'

module.exports = require('../schema/yang-express.yang').bind {

  '[express]':   require('./feature/express')
  '[restjson]':  require('./feature/restjson')
  '[openapi]':   require('./feature/openapi')
  '[websocket]': require('./feature/websocket')

  '/server/hostname': -> @content ?= require('os').hostname()

  run: ->
    express = @require 'express'
    server = @get('/server')
    server.port = @input.port
    server.hostname = @input.hostname
    
    @output = new Promise (resolve, reject) ->
      express.listen server.port, server.hostname
      express.on 'listening', ->
        resolve 'running'
      
}
