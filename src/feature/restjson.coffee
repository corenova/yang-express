# RESTJSON YANG model-driven middleware router feature binding

debug = require('debug')('yang-express:restjson') if process.env.DEBUG?
express = require 'express'
bp = require 'body-parser'

module.exports = ->
  ctx = this
  unless @content?
    @engine.once "enable:restjson", (restjson) ->
      debug? "enabling feature into express"
      app = @express
      app.set 'json spaces', 2
      app.enable 'restjson'
      app.use restjson
  @content ?= (->
    @use bp.urlencoded(extended:true), bp.json(strict:true, type:'*/json')
    @use (req, res, next) ->
      return next 'route' if req.app.disabled('restjson') or req.path is '/'
      routers = ctx.get('/server/router/name')
      routers = [ routers ] unless Array.isArray routers
      debug? "searching #{routers}"
      for router in routers when ctx.access(router).in(req.path)?
        debug? "found '#{router}' for #{req.path}"
        req.model = ctx.access router
        break
      next()
      
    transact = (target, callback=->this) -> switch
      when Array.isArray target then target.map (x) -> callback.call(x).toJSON()
      else callback.call(target).toJSON()

    @route '*'
    .all (req, res, next) ->
      if req.model? and req.accepts('json')
        debug? "calling #{req.method} on #{req.path}"
        req.prop = req.model.in(req.path)
        next()
      else next 'route'
        
    .get    (req, res, next) -> res.send (transact req.prop)
    .put    (req, res, next) -> res.send (transact req.prop, -> @set req.body)
    .patch  (req, res, next) -> res.send (transact req.prop, -> @merge req.body)
    .delete (req, res, next) -> res.send (transact req.prop, -> @remove())
    
    .options (req, res, next) ->
      if Array.isArray req.prop then next 'route'
      else res.send req.prop.inspect()
        
    .post (req, res, next) ->
      switch
        when Array.isArray req.prop then next 'route'
        when req.prop.kind in [ 'rpc', 'action' ]
          req.prop.invoke(req.body)
            .then (res) -> res.send res
            .catch (err) -> res.status(500).send err
        when req.prop.kind is 'list' and not req.prop.key?
          res.status(201).send (transact req.prop, -> @create req.body)
        else res.status(400).end()

    # setup default error handler
    @use (err, req, res, next) ->
      if err instanceof Error
        console.error err.stack
        err =
          name:    err.name
          message: err.message
          context: err.context?.toString()
      res.status(500).send(error: err)
      
    return this
  ).call express.Router()
