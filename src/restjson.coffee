# RESTJSON interface feature
#

bp = require 'body-parser'

restjson = (opts={}, done=->) ->
  @set 'json spaces', opts.spaces ? 2
  @use bp.urlencoded(extended:true), bp.json(strict:true, type:'*/json')

  transact = (target, callback=->this) -> switch
    when Array.isArray target then target.map (x) -> callback.call(x).valueOf()
    else callback.call(target).valueOf()

  @route '*'
  .all (req, res, next) ->
    if req.app.enabled('restjson') and req.link? and req.accepts('json')
      console.log "[restjson:#{req.link.name}] calling #{req.method} on #{req.path}"
      req.prop = req.link.in req.path
      next()
    else next 'route'

  .get    (req, res, next) -> res.send (transact req.prop)
  .put    (req, res, next) -> res.send (transact req.prop, -> @set req.body)
  .patch  (req, res, next) -> res.send (transact req.prop, -> @merge req.body)
  .delete (req, res, next) -> res.send (transact req.prop, -> @remove())
  
  .post (req, res, next) ->
    kind = req.prop.schema.kind
    switch 
      when kind in [ 'rpc', 'action' ] then res.send "Coming Soon!"
      when kind is 'list' and not req.prop.key?
        res.status(201).send (transact req.prop, -> @create req.body)
      else res.status(400).end()

  .options (req, res, next) ->
    { schema, path, props } = req.prop
    info =
      name: req.prop.name
      kind: schema.kind
      path: "#{req.prop.path}"
    info[k] = v for k, v of schema.attrs
      .filter (x) -> x.kind not in [ 'uses', 'grouping' ]
      .reduce ((a,b) ->
        for k, v of b.toObject()
          if a[k] instanceof Object
            a[k][kk] = vv for kk, vv of v if v instanceof Object
          else
            a[k] = v
        return a
      ), {}
    if schema.nodes.length > 0
      info.props = schema.nodes.reduce ((a,b) ->
        a[b.tag] = kind: b.kind
        a[b.tag][k] = v for k, v of b.attrs
          .filter (x) -> x.kind not in [ 'uses', 'grouping' ]
          .reduce ((a,b) -> a[k] = v for own k, v of b.toObject(); a), {}
        return a
      ), {}
    res.send info
  done restjson

# TODO: room for optimization here... (should be agnostic to openapi/swagger)
restjson.paths = (schema) ->
  schema.nodes.reduce ((a,b) ->
    return a unless b.kind in [ 'list', 'container' ]
    
    path = "/#{b.datakey}"
    subpaths = restjson.paths(b) 
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

module.exports = restjson
