'use strict';

const debug = require('debug')('yang:express:restjson');
const Router = require('express').Router;

const restjson = (options = {}) => {
  const {
    bodyparser = require('body-parser'),
    multipart  = require('multer'),
  } = options;
  const router = Router();
  const bp = bodyparser;
  const mp = multipart();

  // middleware generator for common REST operations
  const transact = (callback) => {
    if (!callback)
      throw new Error('must specify callback function for transact')
    
    return (req, res, next) => {
      const { match } = res.locals
      if (Array.isArray(match)) {
        res.send(match.map((x) => callback.call(x, req.body).toJSON(true)))
      } else {
        res.send(callback.call(match, req.body).toJSON(true))
      }
    }
  }

  // setup JSON body parser
  router.use(bp.urlencoded({ extended: true }), bp.json({ strict: true, type:'*/json'}))
  
  router.route('*')
    .all((req, res, next) => {
      if (req.app.enabled('restjson') &&
          req.accepts('json') &&
          res.locals.match) {
        this.debug(`restjson: handling ${req.method} on ${req.path} using '${res.locals.model.name}' model`)
        next()
      } else {
        this.debug(`restjson: skipping ${req.path}`)
        next('route')
      }
    })
    .options((req, res, next) => {
      const { match } = res.locals
      if (Array.isArray(match)) next('route');
      else res.send(match.inspect());
    })
    .post(mp.any(), (req, res, next) => {
      const { match } = res.locals
      if (Array.isArray(match)) next('route');
      else {
        switch (match.kind) {
        case 'action':
        case 'rpc':
          if (req.files) {
            req.body = req.files.reduce((a,b) => {
              a[b.fieldname] = b.buffer;
              return a;
            },{});
          }
          match.do(req.body)
            .then(out => res.send(out))
            .catch(err => next(err))
          break;
        case 'list':
          const list = match.create(req.body);
          res.status(201).send({ [list.name]: list.change });
          break;
        default:
          res.status(400).end()
        }
      }
    })
    .get(transact(function(data) { return this }))
    .put(transact(function(data) { return this.set(data) }))
    .patch(transact(function(data) { return this.merge(data) }))
    .delete(transact(function(data) { return this.delete() }))
  
  // setup default error handler
  router.use((err, req, res, next) => {
    if (err instanceof Error) {
      let { name, message, context } = err
      const error = { name, message, context: `${context}` }
      res.status(500).send({ error })
    } else next()
  })
  return router
}

module.exports = restjson
