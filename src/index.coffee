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
mrouter = require './model-router'

createApplication = ((opts={}) ->
  unless opts.models instanceof Array and opts.models.length
    throw new Error "must provide one-or-more models"

  @use bp.urlencoded(extended:true), bp.json(strict:true)
  @set 'json spaces', 2

  for model in opts.models
    model = yang.parse model if typeof model is 'string'
    data  = model.eval opts.data
    @use "/#{model.tag}", (mrouter model, data)
  
  return this
).bind express()

exports = module.exports = createApplication
exports.run = (opts={}) ->
  app = createApplication opts
  app.listen (opts.port ? 5050)
