'use strict';

const debug = require('debug')('yang:express:openapi')

function openapi() {
  const Router = this.use('router')
  const router = Router()
  const mimes = [ 'openapi+yaml', 'openapi+json', 'yaml', 'json' ]
  
  router.route('/openapi.spec')
    .all((req, res, next) => {
      if (req.app.enabled('openapi') &&
          req.accepts(mimes) &&
          res.locals.modules) {
        next()
      } else {
        next('route')
      }
    })
    .get((req, res, next) => {
      const { modules } = res.locals
      this.in('/openapi:transform').do({ modules })
        .then((output) => {
          const format = req.accepts('yaml') ? 'yaml' : 'json'
          return output.spec.serialize({ format })
        })
        .then((output) => res.send(output.data))
        .catch((err) => next(err))
    })
  return router
}

module.exports = openapi
