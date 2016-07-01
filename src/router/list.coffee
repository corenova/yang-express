express = require 'express'

module.exports = (->
  @route '/'
  .all (req, res, next) ->
    if res.locals.target.__?.expr.kind is 'list'
      console.log "list router: #{req.originalUrl}"
      next()
    else next 'route'
  .post (req, res, next) ->
    return next "cannot add a new entry without supplying data" unless Object.keys(req.body).length
    items = switch
      when req.body instanceof Array then res.locals.target.add req.body...
      else res.locals.target.add req.body
    res.locals.result = items

  @get '/:key', (req, res, next) ->
    match = res.locals.target["__#{req.params.key}__"]
    if match?
      res.locals.result = match
      next()
    else next 'route'

  @delete '/:key', (req, res, next) ->
    return next 'route' unless res.locals.target.remove?
    res.locals.target.remove req.params.key
      
  return this
).call express.Router()
