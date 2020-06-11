const debug = require('debug')('yang:express');

const discover = require('./lib/discover');
const restjson = require('./lib/restjson');

module.exports = {
  discover, restjson,
};
