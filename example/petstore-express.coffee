require 'yang-js'

petstore = require('./petstore.yang').eval require('./petstore.json')
petstore.on 'update', '/pet', (prop) ->
  console.log "[@name] update for #{prop.path}"  

express = module.exports = require('..').eval require('./petstore.json')
express.enable 'openapi'

# only start if directly invoked
express.invoke 'run' if require.main is module
