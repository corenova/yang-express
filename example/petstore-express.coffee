require 'yang-js'

data = require('./petstore.json')
petstore = require('./petstore.yang').eval(data)
petstore.on 'update', '/pet', (prop) ->
  console.log "[@name] update for #{prop.path}"  

express = require('..').eval(data)
express
  .enable 'restjson'
  .enable 'openapi'

module.exports = express

# only start if directly invoked
if require.main is module
  yaml = require 'js-yaml'
  express.invoke('run')
  .then (res) ->
    console.info "petstore-express running with:"
    console.info yaml.dump(res)
  .catch (err) -> console.error err
