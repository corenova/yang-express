express = require 'express'

module.exports = ((model, data) ->
  unless model?
    console.log model
    throw new Error "must supply Yang data model to create model router"

  @route '*'
  .all (req, res, next) ->
    req.y = model.access req.path, data
    if req.y? then next()
    else next 'route'

  .get (req, res, next) ->
    { schema, path, match, key } = req.y
    console.log "[#{model.tag}] calling GET on #{path}"
    unless match?
      return res.status(404).end()
    res.send switch
      when key? then "#{key}": match
      else match

  .put (req, res, next) ->
    { schema, path, match, key } = req.y
    console.log "[#{model.tag}] calling PUT on #{path}"
    unless match?
      return res.status(404).end()
    unless typeof match is 'object'
      console.warn "[#{model.tag}] cannot PUT on '#{schema.kind}'"
      return res.status(400).end()

    match[k] = v for own k, v of req.body when match.hasOwnProperty k
    # TODO: should trigger validation...
    res.send switch
      when key? then "#{key}": match
      else match

  .post (req, res, next) ->
    { schema, path, match, key } = req.y
    console.log "[#{model.tag}] calling POST on #{path}"
    switch schema.kind
      when 'rpc', 'action' then res.send "Coming Soon!"
      when 'list'
        unless match instanceof Array
          return res.status(400).end()
          
        unless key of req.body
          req.body = "#{key}": req.body
        list = schema.eval(req.body)[key]
        list = [ list ] unless list instanceof Array
        for item in list
          match.__._value[key].add item
        res.status(201).send switch
          when key? then "#{key}": list
          else list
      else
        console.warn "[#{model.tag}] cannot POST on '#{schema.kind}'"
        res.status(400).end()
        
  .delete (req, res, next) ->
    { schema, path, match, key } = req.y
    console.log "[#{model.tag}] calling DELETE on #{path}"
    unless match?
      return res.status(404).end()
    unless schema.kind is 'list' and match not instanceof Array
      console.warn "[#{model.tag}] cannot DELETE on '#{schema.kind}'"
      return res.status(400).end()
    match.__?.parent.remove match['@key']
    res.status(204).end()
    
  .options (req, res, next) ->
    { schema, path, match, key } = req.y
    console.log "[#{model.tag}] calling OPTIONS on #{path}"
    info =
      name:   schema.datakey
      kind:   schema.kind
      path:   "#{path}"
      exists: match?
    info[k] = v for k, v of schema.exprs
      .filter (x) -> x.data isnt true and x.kind not in [ 'uses', 'grouping' ]
      .reduce ((a,b) -> a[k] = v for own k, v of b.toObject(); a), {}
    nodes = schema.exprs.filter (x) -> x.data is true
    if nodes.length > 0
      info.data = nodes.reduce ((a,b) ->
        a[b.tag] = kind: b.kind
        a[b.tag][k] = v for k, v of b.exprs
          .filter (x) -> x.data isnt true and x.kind not in [ 'uses', 'grouping' ]
          .reduce ((a,b) -> a[k] = v for own k, v of b.toObject(); a), {}
        return a
      ), {}
    res.send info
    
  .report  (req, res, next) -> res.send 'TBD'
  .copy    (req, res, next) -> res.send 'TBD'
  
  return this
).bind express.Router()
