'use strict';
var Action, Entity, Symbol, actionPool, bData, fast, listPool, log, poolAction, poolList, symbols, _;

log = (require('debug'))('scent:action');

_ = require('lodash');

fast = require('fast.js');

Symbol = require('es6').Symbol;

bData = Symbol('internal data of the action type');

symbols = require('./symbols');

Entity = require('./entity');

Action = function(name) {
  var actionType;
  if (!_.isString(name)) {
    throw new TypeError('missing name of the action type');
  }
  actionType = Object.create(Action.prototype);
  actionType[symbols.bName] = name;
  actionType[bData] = {};
  return Object.freeze(actionType);
};

Action.prototype = Object.create(Function.prototype);

Action.prototype.trigger = function(entity) {
  var action, data, dataArg, i, target, val, _i, _len;
  action = poolAction();
  action.entity = entity;
  action.time = Date.now();
  if (arguments.length > 1 && _.isPlainObject(dataArg = arguments[1])) {
    action.get = function(prop) {
      return dataArg[prop];
    };
  }
  for (i = _i = 0, _len = arguments.length; _i < _len; i = ++_i) {
    val = arguments[i];
    if (i > 0) {
      action.push(val);
    }
  }
  data = this[bData];
  if (data.frozen) {
    if (!data.buffer) {
      data.buffer = poolList();
    }
    target = data.buffer;
  } else {
    if (!data.list) {
      data.list = poolList();
    }
    target = data.list;
  }
  target.push(action);
};

Action.prototype.each = function(iterator) {
  var action, data, _i, _len, _ref, _ref1;
  if (!(iterator && _.isFunction(iterator))) {
    throw new TypeError('expected iterator function for the each call');
  }
  data = this[bData];
  data.frozen = true;
  if (!((_ref = data.list) != null ? _ref.length : void 0)) {
    return;
  }
  _ref1 = data.list;
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    action = _ref1[_i];
    iterator.call(iterator, action);
  }
};

Action.prototype.finish = function() {
  var action, data, _i, _len, _ref;
  data = this[bData];
  if (data.list) {
    _ref = data.list;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      action = _ref[_i];
      action.length = 0;
      poolAction(action);
    }
    data.list.length = 0;
    poolList(data.list);
    data.list = null;
  }
  data.list = data.buffer;
};

listPool = [];

poolList = function(add) {
  if (add) {
    return listPool.push(add);
  }
  if (!listPool.length) {
    return [];
  }
  return listPool.pop();
};

actionPool = [];

poolAction = function(add) {
  if (add) {
    return actionPool.push(add);
  }
  if (!actionPool.length) {
    return [];
  }
  return actionPool.pop();
};

module.exports = Object.freeze(Action);
