require('yang-js').register()

app = require('..') ->
  @enable 'openapi', {
    title: 'Yang Petstore'
    description: 'Example'
    version: '0.1'
    contact: {
      name: 'John Doe'
      url: 'http://github.com/corenova/yang-express'
    }
    license: {
      name: 'Apache-2.0'
    }
  }
  @enable 'yangapi'
  @enable 'restjson'
  @enable 'websocket'

  @open 'petstore', ->
    @import  require('./petstore.yang')
    @connect require('./petstore.json')

    @on 'update', '/petstore:pet', (prop) ->
      console.log "[@name] update for #{prop.path}"

module.exports = app

# only start if directly invoked
app.listen 5000 if require.main is module
  

