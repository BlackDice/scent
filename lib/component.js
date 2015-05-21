'use strict';
var BaseComponent, Component, Map, NoMe, Set, Symbol, _, bData, bPool, bSetup, defineFieldProperty, emptyFields, fast, fieldsRx, identities, identityRx, initializeData, log, poolMap, ref, symbols;

log = (require('debug'))('scent:component');

_ = require('lodash');

fast = require('fast.js');

NoMe = require('nome');

ref = require('es6'), Symbol = ref.Symbol, Map = ref.Map, Set = ref.Set;

symbols = require('./symbols');

bPool = Symbol('pool of disposed components');

bData = Symbol('data array for the component');

bSetup = Symbol('private setup method for component');

identities = fast.clone(require('./primes')).reverse();

fieldsRx = /(?:^|\s)([a-z][a-z0-9]*(?=\s|$))/gi;

identityRx = /(?:^|\s)#([0-9]+(?=\s|$))/i;

Component = function(name, definition) {
  var ComponentType;
  if (definition instanceof Component) {
    return definition;
  }
  if (!_.isString(name)) {
    throw new TypeError('missing name of the component');
  }
  ComponentType = function(data) {
    var component;
    component = this;
    if (!(component instanceof ComponentType)) {
      component = new ComponentType(data);
    }
    initializeData(component, ComponentType.typeFields, data);
    return component;
  };
  ComponentType.prototype = new BaseComponent(name, definition);
  ComponentType.prototype[symbols.bType] = ComponentType;
  Object.setPrototypeOf(ComponentType, Component.prototype);
  return Object.freeze(ComponentType);
};

Component.prototype = Object.create(Function.prototype);

poolMap = new Map;

Component.prototype.pooled = function() {
  var pool;
  if ((pool = poolMap.get(this)) == null) {
    poolMap.set(this, pool = []);
  }
  if (pool.length) {
    return pool.pop();
  }
  return new this;
};

Component.prototype.toString = function() {
  var fields, type;
  type = this.prototype;
  return ("ComponentType `" + type[symbols.bName] + "` #" + type[symbols.bIdentity]) + (!(fields = type[symbols.bFields]) ? "" : " [" + (fields.join(' ')) + "]");
};

Object.defineProperties(Component.prototype, {
  'typeName': {
    enumerable: true,
    get: function() {
      return this.prototype[symbols.bName];
    }
  },
  'typeIdentity': {
    enumerable: true,
    get: function() {
      return this.prototype[symbols.bIdentity];
    }
  },
  'typeFields': {
    enumerable: true,
    get: function() {
      return this.prototype[symbols.bFields];
    }
  },
  'typeDefinition': {
    enumerable: true,
    get: function() {
      var fields;
      return ("#" + this.prototype[symbols.bIdentity]) + (!(fields = this.prototype[symbols.bFields]) ? "" : " " + (fields.join(' ')));
    }
  }
});

Component.disposed = NoMe(function() {
  return this[symbols.bDisposing] = Date.now();
});


/*
 * BaseComponent
 */

BaseComponent = function(name, definition) {
  var field, i, j, len, ref1;
  this[symbols.bName] = name;
  this[bSetup](definition);
  ref1 = this[symbols.bFields];
  for (i = j = 0, len = ref1.length; j < len; i = ++j) {
    field = ref1[i];
    defineFieldProperty(this, field, i);
  }
  return this;
};

BaseComponent.prototype[bSetup] = function(definition) {
  var field, fields, identity, identityMatch, idx, match;
  if (typeof definition === 'undefined' || (definition == null)) {
    this[symbols.bIdentity] = identities.pop();
    return;
  }
  if (typeof definition !== "string") {
    throw new TypeError('optionally expected string definition for component type, got:' + definition);
  }
  fields = null;
  while (match = fieldsRx.exec(definition)) {
    if (fields == null) {
      fields = [];
    }
    if (!~(fast.indexOf(fields, field = match[1]))) {
      fields.push(field);
    }
  }
  if (fields != null) {
    this[symbols.bFields] = Object.freeze(fields);
  }
  if (identityMatch = definition.match(identityRx)) {
    identity = Number(identityMatch[1]);
    if (!~(idx = fast.indexOf(identities, identity))) {
      throw new Error('invalid identity specified for component: ' + identity);
    }
    identities.splice(idx, 1);
  } else {
    identity = identities.pop();
  }
  this[symbols.bIdentity] = identity;
};

BaseComponent.prototype[symbols.bName] = null;

BaseComponent.prototype[symbols.bIdentity] = null;

BaseComponent.prototype[symbols.bFields] = emptyFields = Object.freeze([]);

BaseComponent.prototype[symbols.bChanged] = 0;

BaseComponent.prototype[symbols.bDispose] = Component.disposed;

BaseComponent.prototype[symbols.bRelease] = function() {
  var data, pool;
  if (!this[symbols.bDisposing]) {
    return false;
  }
  delete this[symbols.bDisposing];
  if (data = this[bData]) {
    data.length = 0;
    delete this[symbols.bChanged];
  }
  if (pool = poolMap.get(this[symbols.bType])) {
    pool.push(this);
  }
  return true;
};

BaseComponent.prototype.toString = function() {
  var changed, fields;
  return ("Component `" + this[symbols.bName] + "` #" + this[symbols.bIdentity]) + (!(fields = this[symbols.bFields]) ? "" : (" [" + (fields.join(' ')) + "]") + (!(changed = this[symbols.bChanged]) ? "" : "(changed: " + changed + ")"));
};

BaseComponent.prototype.inspect = function() {
  var field, j, len, ref1, result;
  result = {
    "--typeName": this[symbols.bName],
    "--typeIdentity": this[symbols.bIdentity],
    "--changed": this[symbols.bChanged]
  };
  if (this[symbols.bDisposing]) {
    result['--disposing'] = this[symbols.bDisposing];
  }
  ref1 = this[symbols.bFields];
  for (j = 0, len = ref1.length; j < len; j++) {
    field = ref1[j];
    result[field] = this[field];
  }
  return result;
};

Object.freeze(BaseComponent);

defineFieldProperty = function(target, field, i) {
  return Object.defineProperty(target, field, {
    enumerable: true,
    get: function() {
      var val;
      if (void 0 === (val = this[bData][i])) {
        return null;
      } else {
        return val;
      }
    },
    set: function(val) {
      this[symbols.bChanged] = Date.now();
      return this[bData][i] = val;
    }
  });
};

initializeData = function(component, fields, data) {
  if (!fields.length) {
    return;
  }
  if (data && _.isArray(data)) {
    data.length = fields.length;
    component[bData] = data;
  } else {
    component[bData] = new Array(fields.length);
  }
};

if (typeof IN_TEST !== 'undefined') {
  Component.identities = identities;
}

module.exports = Object.freeze(Component);
