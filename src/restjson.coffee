# RESTJSON interface feature
#
 
bp = require 'body-parser'

module.exports = (done=->) ->
  @set 'json spaces', 2
  @use bp.urlencoded(extended:true), bp.json(strict:true, type:'*/json')

  @route '*'
  .all (req, res, next) ->
    if req.app.enabled('restjson') and req.link? and req.accepts('json')
      next()
    else next 'route'

  .get (req, res, next) ->
    { model, schema, path, match, key } = req.link
    console.log "[restjson:#{model._id}] calling GET on #{path}"
    unless match?
      return res.status(404).end()
    res.send switch
      when key? then "#{key}": match
      else match

  .put (req, res, next) ->
    { model, schema, path, match, key } = req.link
    console.log "[restjson:#{model._id}] calling PUT on #{path}"
    unless match?
      return res.status(404).end()
    unless typeof match is 'object'
      console.warn "[restjson:#{model._id}] cannot PUT on '#{schema.kind}'"
      return res.status(400).end()

    match[k] = v for own k, v of req.body when match.hasOwnProperty k
    # TODO: should trigger validation...
    res.send switch
      when key? then "#{key}": match
      else match

  .post (req, res, next) ->
    { model, schema, path, match, key } = req.link
    console.log "[restjson:#{model._id}] calling POST on #{path}"
    switch schema.kind
      when 'rpc', 'action' then res.send "Coming Soon!"
      when 'list'
        unless match instanceof Array
          return res.status(400).end()
        unless key of req.body
          req.body = "#{key}": req.body
        list = schema.apply(req.body)[key]
        list = [ list ] unless list instanceof Array
        match.__.content.add item for item in list
        res.status(201).send switch
          when key? then "#{key}": list
          else list
      else
        console.warn "[restjson:#{model._id}] cannot POST on '#{schema.kind}'"
        res.status(400).end()

  .delete (req, res, next) ->
    { model, schema, path, match, key } = req.link
    console.log "[restjson:#{model._id}] calling DELETE on #{path}"
    unless match?
      return res.status(404).end()
    unless schema.kind is 'list' and match not instanceof Array
      console.warn "[restjson:#{model._id}] cannot DELETE on '#{schema.kind}'"
      return res.status(400).end()

    match.__?.parent.remove match['@key']
    res.status(204).end()

  .options (req, res, next) ->
    { model, schema, path, match, key } = req.link
    console.log "[restjson:#{model._id}] calling OPTIONS on #{path}"
    info =
      name:   schema.datakey
      kind:   schema.kind
      path:   "#{path}"
      exists: match?
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
      info.paths = schema.nodes.reduce ((a,b) ->
        a[b.tag] = kind: b.kind
        a[b.tag][k] = v for k, v of b.attrs
          .filter (x) -> x.kind not in [ 'uses', 'grouping' ]
          .reduce ((a,b) -> a[k] = v for own k, v of b.toObject(); a), {}
        return a
      ), {}
    res.send info
    
  done()
