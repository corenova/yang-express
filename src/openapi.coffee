# OPENAPI (swagger) specification feature
#
# TODO: this spec should be YANG validated

yaml = require 'js-yaml'
os   = require 'os'

mimes = [ 'openapi+yaml', 'openapi+json', 'yaml', 'json' ]
module.exports = (done=->)->
  @set 'json spaces', 2

  @route '/swagger.spec'
  .all (req, res, next) ->
    if req.app.enabled('openapi')
      next()
    else next 'route'

  .get (req, res, next) ->
    { info, pkginfo, links } = req.app.settings
    info ?= {}
    info.title ?= pkginfo.name
    info.description ?= pkginfo.description
    info.version ?= pkginfo.version
    info.contact ?=
      name: pkginfo.author
      url:  pkginfo.homepage
    info.license ?=
      name: pkginfo.license
    spec =
      swagger: '2.0'
      info: info
      host: "#{os.hostname()}:#{req.app.get('port')}"
      consumes: [ "application/json" ]
      produces: [ "application/json" ]
      # TODO: need to discover from 'restjson'
      paths: links.reduce ((a,link) ->
        { schema } = link.access '/'
        paths = switch
          when schema.kind is 'module'
            schema.nodes.reduce ((a,b) ->
              a["/#{b.tag}"] = b.toObject()
              return a
            ), {}
          else "/#{schema.tag}": schema.toObject()
        a[k] = v for k, v of paths
        return a
      ), {}
    res.format
      json: -> res.send spec
      yaml: -> res.send (yaml.dump spec)
        
  done()
