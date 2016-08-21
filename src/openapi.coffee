# OPENAPI (swagger) specification feature
#
# TODO: this spec should be YANG validated

yaml = require 'js-yaml'
os   = require 'os'

mimes = [ 'openapi+yaml', 'openapi+json', 'yaml', 'json' ]
exports = module.exports = (opts={}, done=->)->
  @set 'json spaces', 2

  info = switch
    when opts.name? and opts.main? # package.json
      title:       opts.name
      description: opts.description
      version:     opts.version
      contact:
        name: opts.author
        url:  opts.homepage
      license:
        name: opts.license
    else opts

  @route '/openapi.spec'
  .all (req, res, next) ->
    if req.app.enabled('openapi') and req.app.enabled('restjson')
      next()
    else next 'route'

  .get (req, res, next) ->
    { restjson, links } = req.app.settings
    spec =
      swagger: '2.0'
      info: info
      host: "#{os.hostname()}:#{req.app.get('port')}"
      consumes: [ "application/json" ]
      produces: [ "application/json" ]
      paths: links.reduce ((a,link) ->
        model = link.in '/'
        schema = model.__.schema
        a[k] = v for k, v of restjson.paths(schema)
        return a
      ), {}
      definitions: links.reduce ((a,link) ->
        model = link.in '/'
        schema = model.__.schema
        getdefs = (schema) ->
          match = schema.nodes.filter (x) -> x.kind in [ 'list', 'container' ]
          match.reduce ((a,b) -> a.concat (getdefs b)... ), match
        for def in getdefs (schema)
          o = 
            required: []
            properties: {}
          for prop in def.nodes
            if prop.mandatory?.tag is true
              o.required.push prop.tag
            # TODO: need to traverse to the most primitive type
            o.properties[prop.tag] = type: prop.type?.tag ? 'string'
          a[def.tag] = o
          if def.kind is 'list'
            a["#{def.tag}s"] =
              type: 'array'
              items: '$ref': "#/definitions/#{def.tag}"
        return a
      ), {}
    res.format
      json: -> res.send spec
      yaml: -> res.send (yaml.dump spec)
      
  done exports
  
exports.mimes = mimes
