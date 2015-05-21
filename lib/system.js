var _, symbols;

_ = require('lodash');

symbols = require('./symbols');

exports.define = function(name, initializer) {
  if (!_.isString(name)) {
    throw new TypeError('expected name for system');
  }
  if (!_.isFunction(initializer)) {
    throw new TypeError('expected function as system initializer');
  }
  initializer[symbols.bName] = name;
  return Object.freeze(initializer);
};
