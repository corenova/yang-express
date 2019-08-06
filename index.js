const initialize = ({ modules = [], store }) => {
  const models = modules.map(name => store.access(name));
  return (req, res, next) => {
    if (req.path === '/') {
      res.locals = { model: store, match: store };
      return next();
    }
    for (let model of models) {
      const match = model.in(req.path);
      if (match) {
        this.debug(`discover: found '${name}' model for ${req.path}`)
        res.locals = { model, match }
        break;
      }
    }
    return next('route');
  };
};

const restjson = require('./lib/restjson');

module.exports = {
  initialize, restjson,
};
