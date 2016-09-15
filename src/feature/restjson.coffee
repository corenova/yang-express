# RESTJSON YANG model-driven middleware router feature

module.exports = ->
  feature = this
  express = @use('express')
  express.set 'json spaces', 2
  express.use (req, res, next) =>
    return next 'route' if req.path is '/'
    for router in @get('/server/router/name') when @access(router).in(req.path)?
      req.model = @access router
      break
    next()
  express.mount ->
    bp = require 'body-parser'
    @use bp.urlencoded(extended:true), bp.json(strict:true, type:'*/json')

    transact = (target, callback=->this) -> switch
      when Array.isArray target then target.map (x) -> callback.call(x).valueOf()
      else callback.call(target).valueOf()

    @route '*'
    .all (req, res, next) ->
      if feature.enabled and req.model? and req.accepts('json')
        console.log "[restjson:#{req.model.name}] calling #{req.method} on #{req.path}"
        req.prop = req.model.in req.path
        next()
      else next 'route'

    .get    (req, res, next) -> res.send (transact req.prop)
    .put    (req, res, next) -> res.send (transact req.prop, -> @set req.body)
    .patch  (req, res, next) -> res.send (transact req.prop, -> @merge req.body)
    .delete (req, res, next) -> res.send (transact req.prop, -> @remove())

    .post (req, res, next) ->
      return next 'route' if Array.isArray req.prop
      kind = req.prop.schema.kind
      switch 
        when kind in [ 'rpc', 'action' ] then res.send "Coming Soon!"
        when kind is 'list' and not req.prop.key?
          res.status(201).send (transact req.prop, -> @create req.body)
        else res.status(400).end()

    .options (req, res, next) ->
      return next 'route' if Array.isArray req.prop
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
