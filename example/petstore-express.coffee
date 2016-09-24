require 'yang-js'

petstore = require('./petstore.yang').eval require('./petstore.json')
petstore.on 'update', '/pet', (prop) ->
  console.log "[@name] update for #{prop.path}"  

express = module.exports = require('..').eval require('./petstore.json')
express
  .enable 'restjson'
  .enable 'openapi'

# only start if directly invoked
if require.main is module
  express.invoke('run')
  .then  (res) ->
    console.info "petstore-express running with:"
    console.info res
  .catch (err) -> console.error err
    
