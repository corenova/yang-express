# YANGAPI management feature
#
# Still in *development*

express = require 'express'
StoreRouter = (->
  @route '/:store'
  .all (req, res, next) ->
    if req.all.enabled('yangapi') and req.app.enabled(req.params.store)
      req.store = req.app.get(req.params.store)
      next()
    else next 'route'

  return this
).call express.Router()

ModuleRouter = (->
  @route '/:module.yang'
  .all (req, res, next) ->
    if req.store? and req.params.module of req.store.data
      next()
    else next 'route'

  .get (req, res, next) ->
    console.log "[yangapi] calling GET on #{req.path}"
    unless req.link? and req.app.enabled("link:#{req.link._id}")
      return res.status(404).end()
    { schema } = req.link.__
    res.format
      yang: -> res.send "#{schema}"

  .post (req, res, next) ->
    console.log "[yangapi] calling POST on #{req.path}"
    if req.link?
      console.warn "[yangapi] cannot POST on #{req.path} (link exists)"
      res.status(500).end()
    req.app.link req.body

  .delete (req, res, next) ->
    console.log "[yangapi] calling DELETE on #{req.path}"
    unless req.link?
      return res.status(404).end()
    req.app.unlink req.link._id

  return this
).call express.Router()

yangapi = (opts={}, done=->)->
  opts.path ?= '/yangapi'
  @use opts.path, StoreRouter, SchemaRouter
  done yangapi

module.exports = yangapi
