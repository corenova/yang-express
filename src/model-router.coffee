express = require 'express'

module.exports = ((model, data) ->
  @route '*'
  .all (req, res, next) ->
    req.yang = model.locate req.path
    if req.yang? then next()
    else next 'route'
  .get (req, res, next) ->
    if req.yang.kind in [ 'module', 'container', 'list' ]
      console.log data
      if data.hasOwnProperty '__'
        res.send data.__.get "#{req.path}"
        next()
      else res.status(404).end()
    else res.status(404).end()
  .put (req, res, next) ->
    if req.yang.kind in [ 'module', 'container', 'list' ]
      if req.path is '/'
        target = data[model.tag] = req.body
      else
        target = data[model.tag].__.get "/#{model.tag}#{req.path}"
        target?.__.set req.body
      if target?
        res.send target
      else res.status(400).end()
    else res.status(404).end()
  .post (req, res, next) ->
    switch req.yang.kind
      when 'rpc', 'action'
        if req.yang.input?
          req.body = req.yang.input.eval req.body
          next()
      when 'list'
        if req.yang.tag of req.body
          req.body = req.yang.eval req.body
          next()
        else res.status(400).end()
      else res.status(404).end()
  .options (req, res, next) -> res.send 'TBD'
  .report  (req, res, next) -> res.send 'TBD'
  .copy    (req, res, next) -> res.send 'TBD'
  
  return this
).bind express.Router()
