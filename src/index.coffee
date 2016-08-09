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

createApplication = ((opts={}) ->
  unless opts.models instanceof Array and opts.models.length
    throw new Error "must provide one (or more) models"
  unless opts.controllers instanceof Array and opts.controllers.length
    throw new Error "must provide one (or more) controllers"

  # bind the models 
  @locals.models = opts.models.map (model) -> switch
    when typeof model is 'string' then yang.parse model
    else model

  # bind the data
  @locals.data = opts.data
  @locals.data = model.eval @locals.data for model in @locals.models

  # bind the controller(s)
  @locals.controllers = opts.controllers.map (controller) -> switch
    when typeof controller is 'string' then require "./#{controller}"
    else controller
  @locals.controllers.forEach (control) => control this

  # bind the view(s) if any
  @locals.views = opts.views ? []
  @locals.views.forEach (view) => view this

  # setup default error handler
  @use (err, req, res, next) ->
    console.error err.stack
    res.status(500).send(error: message: err.message)

  # attach a 'run' function
  @run = (port=5000) =>
    console.log "listening on #{port}"
    @emit 'run', @listen port
    return this
  
  return this
).bind express()

exports = module.exports = createApplication
