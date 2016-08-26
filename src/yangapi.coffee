# YANGAPI management feature

yangapi = (opts={}, done=->)->
  @route '/:module.yang'
  .all (req, res, next) ->
    { links } = req.app.settings
    if req.app.enabled('yangapi')
      for link in links when link._id is req.params.module
        req.link = link
        break
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
  done yangapi

module.exports = yangapi
