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
  try
    @locals.model = model = yang.parse opts.schema
    @locals.data  = data  = model.eval opts.data
  catch e
    console.error "unable to initialize yang-express without valid opts.schema"
    throw e

  @use bp.urlencoded(extended:true), bp.json(strict:true)

  @use "/#{model.tag}", (->
    @route '*'
    .all (req, res, next) ->
      req.yang = model.locate req.path
      if req.yang? then next()
      else next 'route'
    .get (req, res, next) ->
      if req.yang.kind in [ 'module', 'container', 'list' ]
        if data[model.tag]?.hasOwnProperty '__'
          res.send data[model.tag].__.get "/#{model.tag}#{req.path}"
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
  ).call express.Router()
  
  return this
).bind express()
