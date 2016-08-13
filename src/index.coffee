# Express (web server) interface feature module
#
# This feature add-on module enables dynamic web server interface
# generation and is used as a `component` of other feature interfaces
# such as [restjson](restjson.litcoffee) and
# [autodoc](autodoc.litcoffee).
#
# It utilizes the [express](http://expressjs.com) web server framework
# to dynamically instanticate the web server and makes itself available
# for higher-order features to utilize it for associating additional routing endpoints.
express = require 'express'
Yang    = require 'yang-js'

FEATURES =
  restjson:  require './restjson'
  websocket: require './websocket'
  openapi:   require './openapi'

createApplication = ((init=->) ->
  @set 'links', []
  
  # overload existing enable/disable
  @enable = ((f, args...) -> args.forEach (name) =>
    if name of FEATURES and @disabled(name)
      console.info "[#{name}] enabling..."
      FEATURES[name]?.call this, (res) ->
        console.info "[#{name}] enabled ok"
    f.call this, name
    @emit 'enable', name
  ).bind this, @enable
  @disable = ((f, args...) -> args.forEach (name) =>
    if name of FEATURES and @enabled(name)
      console.info "[#{name}] disabling feature..."
      #@get(name).destroy?()
    f.call this, name
    @emit 'disable', name
  ).bind this, @disable

  # support new 'link/unlink' method
  @link = (schema) ->
    console.info "[yang-express] registering a new link"
    schema = switch
      when schema instanceof Yang then schema
      when typeof schema is 'string' then Yang.parse schema
      else Yang.compose schema
    
    unless schema instanceof Yang
      throw new Error "must supply Yang data model to create model-driven link"
      
    model = schema.eval @get('initial state')
    @set "link:#{model._id}", model
    @get('links').push model
    @emit 'link', model._id, model
    console.info "[yang-express] registered 'link:#{model._id}'"
    return model
    
  @unlink = (id) ->
    model = @get "link:#{id}"
    return unless model?
    @disable "link:#{id}"
    @emit 'unlink', id, model
  
  # overload existing .listen()
  @listen = ((listen, args...) ->
    server = listen.apply this, args
    server.on 'listening', =>
      @set 'port', server.address().port
      @emit 'running', server
    return server
  ).bind this, @listen

  # setup linker middleware (it ignores '/')
  @use (req, res, next) ->
    return next 'route' if req.path is '/'
    for link in req.app.get('links') when req.app.enabled "link:#{link._id}"
      req.link = link.access req.path
      break if req.link?
    next()

  console.info "[yang-express] start of a new journey"
  init.call this

  # setup default error handler
  @use (err, req, res, next) ->
    console.error err.stack
    res.status(500).send(error: message: err.message)
    
  return this
).bind express()
  
exports = module.exports = createApplication
exports.register = (name, handler) -> FEATURES[name] = handler; this
