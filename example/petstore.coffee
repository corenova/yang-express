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
  
  petstore = @link require('./petstore.yang'), require('./petstore.json')
  petstore.on 'update', (prop, prev) ->
    console.log "update for #{prop.path}"

module.exports = app

# only start if directly invoked
app.listen 5000 if require.main is module
  

