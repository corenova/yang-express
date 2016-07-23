
yang = require('yang-js').register()

module.exports = require('../yang-express.yang').bind {

  '[feature:express]':      require('express')
  '[feature:body-parser]':  require('body-parser')
  '[feature:model-router]': require('./model-router')

  '/server/create-router': (input, resolve, reject) ->
    mrouter = @use('model-router')
    model = switch
      when typeof input.model is 'string'   then yang.parse input.model
      when input.model instanceof yang.Yang then input.model
    unless model?
      return reject "invalid 'schema-model' provided to create-router"

    data = model.eval input.data
    resolve
      model:  model
      router: mrouter model, data
      
  '/server/mount': (input, resolve, reject) ->
    resolve @create 'route',
      name:   input.model.tag
      router: input.router
      
  '/create': (input, resolve, reject) ->
    app  = @use('express')()
    bp   = @use('body-parser')
    data = input.data

    app.use bp.urlencoded(extended:true), bp.json(strict:true)

    unless input.models.length
      # create using existing routes
      routes = @get '/server/route'
      for route in routes when route.router?
        app.use "/#{route.name}", route.router
      return resolve app

    models = input.models.map (model) -> model: model, data: data
    @invokeAll '/server/create-router', models
    .then (routers) =>
      @invokeAll '/server/mount', routers
      .then (routes) =>
        for route in routes when route.router?
          app.use "/#{route.name}", route.router
        resolve app
      
  '/run': (input, resolve, reject) ->
    @invoke '/create', input
    .then (app) ->
      app.listen input.port
      @update '/server/port', input.port
      resolve server: app
    .catch (e) -> reject e
}
