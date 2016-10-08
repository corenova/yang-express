# OPENAPI (swagger) specification feature

debug = require('debug')('yang-express:openapi') if process.env.DEBUG?
config = require 'config'
express = require 'express'
swagger = require('yang-swagger').eval(config)

# TODO: do something with this info...
mimes = [ 'openapi+yaml', 'openapi+json', 'yaml', 'json' ]

module.exports = ->
  ctx = this
  @content ?= (->
    @route '/openapi.spec'
    .all (req, res, next) ->
      return next 'route' unless req.app.enabled('openapi') and req.app.enabled('restjson')
      next()
    .get (req, res, next) ->
      routers = ctx.get('/server/router/name')
      return next 'route' unless routers?
      routers = [ routers ] unless Array.isArray routers
      swagger.in('transform')
        .invoke modules: routers
        .then (spec) ->
          format = switch
            when req.accepts('yaml')? then 'yaml'
            else 'json'
          swagger.in('serialize').invoke spec: spec, format: format
        .then (out) -> res.send out.data
        .catch (err) -> next err
    return this
  ).call express.Router()

  @engine.once "enable:openapi", (openapi) ->
    debug? "enabling feature into express"
    app = @express
    app.set 'json spaces', 2
    app.enable 'openapi'
    app.use openapi
