'use strict';
var Action, ActionType, Entity, Symbol, _, bData, bPool, each$noContext, each$withContext, fast, listPool, log, poolAction, poolList, symbols;

log = (require('debug'))('scent:action');

_ = require('lodash');

fast = require('fast.js');

Symbol = require('es6').Symbol;

bData = Symbol('internal data of the action type');

bPool = Symbol('pool of actions for this type');

symbols = require('./symbols');

Entity = require('./entity');

ActionType = function(name) {
  var actionType;
  if (name == null) {
    throw new TypeError('expected name of an action type');
  }
  if (this instanceof ActionType) {
    actionType = this;
  } else {
    actionType = Object.create(ActionType.prototype);
  }
  actionType[symbols.bName] = name;
  actionType[bData] = {};
  actionType[bPool] = [];
  return actionType;
};

Action = function(type, data1, meta1) {
  this.type = type;
  this.data = data1;
  this.meta = meta1;
};

Action.prototype = Object.create(Array.prototype);

Action.prototype.time = 0;

Action.prototype.type = null;

Action.prototype.data = null;

Action.prototype.meta = null;

Action.prototype.get = function(prop) {
  var ref;
  return (ref = this.data) != null ? ref[prop] : void 0;
};

Action.prototype.set = function(prop, val) {
  if (this.data == null) {
    this.data = {};
  }
  this.data[prop] = val;
  return this;
};

ActionType.prototype.trigger = function(data, meta) {
  var action;
  action = poolAction.call(this);
  action.time = Date.now();
  action.data = data;
  action.meta = meta;
  data = this[bData];
  if (data.buffer) {
    data.buffer.push(action);
  } else {
    if (data.list == null) {
      data.list = poolList();
    }
    data.list.push(action);
  }
  return action;
};

ActionType.prototype.each = function(iterator, ctx) {
  var action, data, fn, i, len, ref, ref1;
  if (!(iterator && _.isFunction(iterator))) {
    throw new TypeError('expected iterator function for the each call');
  }
  data = this[bData];
  if (data.buffer == null) {
    data.buffer = poolList();
  }
  if (!((ref = data.list) != null ? ref.length : void 0)) {
    return;
  }
  fn = ctx ? each$withContext : each$noContext;
  ref1 = data.list;
  for (i = 0, len = ref1.length; i < len; i++) {
    action = ref1[i];
    fn(iterator, action, ctx);
  }
};

each$noContext = function(fn, action) {
  return fn(action);
};

each$withContext = function(fn, action, ctx) {
  return fn.call(ctx, action);
};

ActionType.prototype.finish = function() {
  var action, data, i, len, ref;
  data = this[bData];
  if (data.list) {
    ref = data.list;
    for (i = 0, len = ref.length; i < len; i++) {
      action = ref[i];
      action.data = null;
      action.meta = null;
      poolAction.call(this, action);
    }
    data.list.length = 0;
    poolList(data.list);
    data.list = null;
  }
  data.list = data.buffer;
  data.buffer = null;
};

ActionType.prototype.toString = function() {
  return "ActionType " + this[symbols.bName];
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

poolAction = function(add) {
  var pool;
  pool = this[bPool];
  if (add) {
    return pool.push(add);
  }
  if (!pool.length) {
    return new Action(this);
  }
  return pool.pop();
};

module.exports = Object.freeze(ActionType);
