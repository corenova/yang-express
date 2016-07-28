express = require 'express'
yang    = require 'yang-js'

# helper routine to parse REST URI and discover XPATH and Yang expr based on model
discover = (uri='', data) ->
  expr = this
  keys = uri.split('/').filter (x) -> x? and !!x
  str = ''
  while (key = keys.shift()) and expr?
    if expr.kind is 'list'
      str += "[key() = #{key}]"
      key = keys.shift()
      li = true
      break unless key?
    expr = expr.locate key
    str += "/#{expr.datakey}" if expr?
  return if keys.length or not expr?

  xpath = yang.XPath.parse str
  temp = xpath
  key = temp.tag while (temp = temp.xpath)
  
  match = xpath.eval data if data?
  match = switch
    when not match?.length then undefined
    when /list$/.test(expr.kind) and not li then match
    else match[0]
      
  return {
    schema: expr
    path:   xpath
    match:  match
    key:    key
  }

module.exports = ((model, data) ->
  unless model instanceof yang.Yang
    console.log model
    throw new Error "must supply Yang data model to create model router"

  @route '*'
  .all (req, res, next) ->
    req.y = discover.call model, req.path, data
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
        res.send switch
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
    res.send "#{schema}"
    
  .report  (req, res, next) -> res.send 'TBD'
  .copy    (req, res, next) -> res.send 'TBD'
  
  return this
).bind express.Router()
