# OPENAPI (swagger) specification feature

express = require 'express'
yaml    = require 'js-yaml'

# TODO: do something with this info...
mimes = [ 'openapi+yaml', 'openapi+json', 'yaml', 'json' ]

# TODO: optimize this further
discoverPaths = (schema) ->
  schema.nodes.reduce ((a,b) ->
    return a unless b.kind in [ 'list', 'container' ]

    path = "/#{b.datakey}"
    subpaths = discoverPaths(b) 
    expected = 
      200:
        description: "Expected response for a valid request"
        schema: '$ref': "#/definitions/#{b.tag}"
    a[path] = switch b.kind
      when 'list'
        get:
          summary: "List all #{b.tag}(s)"
          responses:
            200:
              description: "Expected response for a valid request"
              schema: '$ref': "#/definitions/#{b.tag}s"
        post:
          summary: "Create a #{b.tag}"
          responses:
            201:
              schema: '$ref': "#/definitions/#{b.tag}"
            400:
              description: "Unexpected request"
      when 'container'
        get:
          summary: "View details on #{b.tag}"
          responses: expected
        put:
          summary: "Update details on #{b.tag}"
          responses: expected
    if b.kind is 'list'
      key = b.key?.tag ? 'id'
      a["#{path}/{#{key}}"] = 
        get:
          summary: "View details on #{b.tag}"
          responses: expected
        put:
          summary: "Update details on #{b.tag}"
          responses: expected
        delete:
          summary: "Delete a #{b.tag}"
          responses: expected
      a["#{path}/{#{key}}#{k}"] = v for k, v of subpaths
    a["#{path}#{k}"] = v for k, v of subpaths
    return a
  ), {}

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
      models = routers.map (router) -> ctx.access router
      
      #ctx.access('yang-openapi').in('transform').invoke
      spec = 
        info: ctx.get('/server/info')
        host: "#{ctx.get('/server/hostname')}:#{ctx.get('/server/port')}"
        consumes: [ "application/json" ]
        produces: [ "application/json" ]
        path: models.reduce ((a, model) ->
          a[k] = v for k, v of discoverPaths(model.schema)
          return a
        ), {}
        definition: models.reduce ((a, model) ->
          getdefs = (schema) ->
            match = schema.nodes.filter (x) -> x.kind in [ 'list', 'container' ]
            match.reduce ((a,b) -> a.concat (getdefs b)... ), match
          for def in getdefs(model.schema)
            o = 
              required: []
              properties: {}
            for prop in def.nodes
              if prop.mandatory?.tag is true
                o.required.push prop.tag
              # TODO: need to traverse to the most primitive type
              o.properties[prop.tag] = type: prop.type?.tag ? 'string'
            a[def.tag] = o
            if def.kind is 'list'
              a["#{def.tag}s"] =
                type: 'array'
                items: '$ref': "#/definitions/#{def.tag}"
          return a
        ), {}
      res.format
        json: -> res.send spec
        yaml: -> res.send (yaml.dump spec)
    return this
  ).call express.Router()

  @engine.once "enable:openapi", (openapi) ->
    app = @express
    app.set 'json spaces', 2
    app.enable 'openapi'
    app.use openapi
