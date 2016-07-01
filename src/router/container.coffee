express = require 'express'

module.exports = (->
  @route '/'
  .all (req, res, next) ->
    if res.locals.target.__?.expr.kind is 'container'
      console.log "container router: #{req.originalUrl}"
      next()
    else next 'route'
  .put (req, res, next) ->
    res.locals.target.__.set req.body
    res.locals.result = res.locals.target
    next()
    
  return this
).call express.Router()
