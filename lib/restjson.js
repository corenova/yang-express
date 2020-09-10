'use strict';

const debug = require('debug')('yang:express:restjson');
const Router = require('express').Router;
const bodyparser = require('body-parser');
const multipart  = require('multer');

const restjson = (opts = {}) => {
  const {
    passport = false,
  } = opts;
  const router = Router();
  const bp = bodyparser;
  const mp = multipart();

  // middleware generator for common REST operations
  const transact = (callback) => {
    if (!callback)
      throw new Error('must specify callback function for transact')
    
    return async (req, res, next) => {
      const { match } = res.locals;
      const opts = passport ? { user: req.user } : {}
      if (Array.isArray(match)) {
	const results = await Promise.all(match.map(m => callback(m.context.with(opts), req.body)));
	res.send(results.map(x => x.toJSON(true)));
      } else {
	const result = await callback(match.context.with(opts), req.body);
        res.send(result.toJSON(true));
      }
    }
  }

  // setup JSON body parser
  router.use(bp.urlencoded({ extended: true }),
	     bp.json({ strict: true, type:'*/json'}));
  
  router.route('*')
    .all((req, res, next) => {
      if (req.app.enabled('restjson') &&
          req.accepts('json') &&
          res.locals.match) {
        debug(`handling ${req.method} on ${req.path} using '${res.locals.model.name}' model`)
        next()
      } else {
        debug(`skipping ${req.path}`)
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
      if (Array.isArray(match)) return next('route');
      let ctx = match.context;
      if (passport) {
	ctx = ctx.with({ user: req.user });
      }	    
      switch (match.kind) {
      case 'action':
      case 'rpc':
        if (req.files) {
          req.body = req.files.reduce((a,b) => {
            a[b.fieldname] = b.buffer;
            return a;
          },{});
        }
        ctx.push(req.body)
          .then(out => res.send(out))
          .catch(err => next(err))
        break;
      case 'list':
	ctx.with({ createOnly: true }).push(req.body)
	  .then(change => res.status(201).send({ [ctx.name]: change }))
	  .catch(err => next(err))
        break;
      default:
        res.status(400).end()
      }
    })
    .get(transact((ctx) => ctx))
    .put(transact((ctx, data) => ctx.with({ replace: true }).push(data)))
    .patch(transact((ctx, data) => ctx.push(data)))
    .delete(transact((ctx) => ctx.push(null)))
  
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
