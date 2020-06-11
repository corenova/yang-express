module.exports = ({ modules = [], store }) => (req, res, next) => {
  res.locals.modules = modules;
  if (req.path === '/') {
    res.locals = { model: store, match: store };
    return next();
  }
  
  for (const name of modules) {
    const model = store.access(name);
    if (!model) continue;
    const match = model.in(req.path);
    if (match) {
      ctx.logDebug(`discover: found '${name}' model for ${req.path}`);
      res.locals = { model, match };
      break;
    }
  }
  return next('route');
};
