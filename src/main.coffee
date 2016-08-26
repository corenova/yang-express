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
  yangapi:   require './yangapi'

createApplication = ((init=->) ->
  @set 'stores', []
  
  # overload existing enable
  @enable = ((f, name, opts) ->
    if name of FEATURES and @disabled(name)
      console.info "[#{name}] enabling..."
      FEATURES[name]?.call this, opts, (res) =>
        console.info "[#{name}] enabled ok"
        @set name, res
    else f.call this, name
    @emit 'enable', name
  ).bind this, @enable
  
  # overload existing disable
  @disable = ((f, args...) -> args.forEach (name) =>
    if name of FEATURES and @enabled(name)
      console.info "[#{name}] disabling feature..."
      #@get(name).destroy?()
    f.call this, name
    @emit 'disable', name
  ).bind this, @disable

  # overload existing .listen()
  @listen = ((listen, args...) ->
    server = listen.apply this, args
    server.on 'listening', =>
      @set 'port', server.address().port
      @emit 'running', server
    return server
  ).bind this, @listen

  # provide new 'open' feature which will create a new Yang.Store as
  # necessary
  @open = (name='yang-express', callback) ->
    store = @get name
    store ?= new Yang.Store name
    callback?.call? store
    unless @enabled('name')
      @set name, store
      @get('stores').push store
    return store
  
  # setup builtin linker middleware for current 'app' (it ignores '/')
  @use (req, res, next) =>
    return next 'route' if req.path is '/'
    for store in @get('stores') when store.in(req.path)?
      req.link = store
      break
    next()

  console.info "[yang-express] initializing..."
  init.call this
  console.info "[yang-express] start of a new journey"

  # setup default error handler
  @use (err, req, res, next) ->
    console.error err.stack
    res.status(500).send(error: message: err.message)
    
  return this
).bind express()
  
exports = module.exports = createApplication
exports.register = (name, handler) -> FEATURES[name] = handler; this
