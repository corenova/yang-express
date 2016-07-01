express = require 'express'

module.exports = (->
  @route '/'
  .all (req, res, next) ->
    if res.locals.target.__?.expr.kind is 'module'
      console.log "module router: #{req.originalUrl}"
      next()
    else next 'route'
  .put (req, res, next) ->
    res.locals.target.__.set req.body
    res.locals.result = res.locals.target
    next()
  .options (req, res, next) -> res.send 'TBD'
  .report  (req, res, next) -> res.send 'TBD'
  .copy    (req, res, next) -> res.send 'TBD'

  @param 'action', (req, res, next, action) ->
    if res.locals.target[action] instanceof Function then next()
    else next 'route'

  @route '/:action'
  .options (req, res, next) ->
    res.send 'TBD'
  .post (req, res, next) ->
    res.locals.target[req.params.action](req.body)
    .then (output) -> res.locals.result = output; next()
    .catch (err) -> next err
    
  return this
).call express.Router()
