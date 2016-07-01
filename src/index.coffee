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
yang    = require 'yang-js'
bp      = require 'body-parser'

module.exports = ((opts={}) ->
  @locals.model = switch
    when opts.schema? then yang.parse(opts.schema)
    when opts.data?   then yang.compose(opts.data)
    else yang.Registry
  @locals.store = @locals.model.eval opts.data
  
  @use bp.urlencoded(extended:true), bp.json(strict:true)

  # main routing loop
  @use (->
    @all '*', (req, res, next) ->
      res.locals.target ?= req.app.locals.store
      next()

    @param 'target', (req, res, next, target) ->
      if res.locals.target.hasOwnProperty target
        res.locals.target = res.locals.target[target]
        next()
      else next 'route'

    # reached end of route and getting back current content
    @get '/', (req, res, next) ->
      res.locals.result = req.target
      next()

    @use require('./router/module'), require('./router/container'), require('./router/list')
    
    # nested loop back to self to process additional sub-routes
    @use '/:target', this

    return this
  ).call express.Router()

  @use (req, res, next) ->
    if res.locals.result?
      res.setHeader 'Expires', '-1'
      res.send res.locals.result
      next()
    else next 'route'

  # default 'catch-all' error handler
  @use (err, req, res, next) ->
    console.error err
    res.status(err.status ? 500).send error: switch
      when err instanceof Error then err.toString()
      else JSON.stringify err
      
  return this
).bind express()
