require 'yang-js'

module.exports = require('../schema/yang-express.yang').bind {

  '[express]':   require('./feature/express')
  '[restjson]':  require('./feature/restjson')
  '[openapi]':   require('./feature/openapi')
  '[websocket]': require('./feature/websocket')

  '/server/hostname': -> @content ?= require('os').hostname(); return @content

  run: (input) -> @async (resolve, reject) ->
    server = @get('/server')
    server.port = input.port
    server.hostname = input.hostname
    express = @use('express')
    express.listen server.port, server.hostname
}
