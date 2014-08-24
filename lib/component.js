/*
* The MIT License (MIT)
* Copyright © 2014 Daniel K. (FredyC)
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* 
* Version: 0.0.2
*/
'use strict';
var Component, Map, NoMe, Set, Symbol, bData, bPool, basePrototype, createDataProperty, emptyFields, fast, fieldsRx, identities, identityRx, initializeData, lill, log, parseDefinition, symbols, verifyName, _, _ref;

log = (require('debug'))('scent:component');

_ = require('lodash');

fast = require('fast.js');

lill = require('lill');

NoMe = require('nome');

_ref = require('./es6-support'), Symbol = _ref.Symbol, Map = _ref.Map, Set = _ref.Set;

symbols = require('./symbols');

bPool = Symbol('pool of disposed components');

bData = Symbol('data array for the component');

identities = fast.clone(require('./primes')).reverse();

fieldsRx = /(?:^|\s)([a-z][a-z0-9]+(?=\s|$))/gi;

identityRx = /(?:^|\s)#([0-9]+(?=\s|$))/i;

Component = function(name, definition) {
  var ComponentType, componentPool, componentPrototype, field, fields, i, identity, toString, _i, _len, _ref1;
  verifyName(name);
  _ref1 = parseDefinition(definition), fields = _ref1.fields, identity = _ref1.identity;
  componentPool = [];
  componentPrototype = Object.create(basePrototype);
  for (i = _i = 0, _len = fields.length; _i < _len; i = ++_i) {
    field = fields[i];
    Object.defineProperty(componentPrototype, field, createDataProperty(i));
  }
  ComponentType = function(data) {
    var component;
    if (!data && componentPool.length) {
      component = componentPool.pop();
    } else {
      component = Object.create(componentPrototype);
      initializeData(component, fields, data);
      Object.setPrototypeOf(component, ComponentType.prototype);
    }
    return component;
  };
  ComponentType[bPool] = componentPool;
  ComponentType[symbols.bFields] = fields;
  ComponentType[symbols.bName] = name;
  ComponentType[symbols.bIdentity] = identity;
  toString = ("Component " + name + ": ") + fields.join(', ');
  ComponentType.toString = function() {
    return toString;
  };
  componentPrototype[symbols.bType] = ComponentType;
  componentPrototype[symbols.bChanged] = 0;
  ComponentType.prototype = componentPrototype;
  Object.setPrototypeOf(ComponentType, Component.prototype);
  return Object.freeze(ComponentType);
};

Component.prototype = Object.create(Function.prototype);

verifyName = function(name) {
  if (!_.isString(name)) {
    throw new TypeError('missing name of the component');
  }
};

emptyFields = Object.freeze([]);

parseDefinition = function(definition) {
  var field, fields, identity, identityMatch, idx, match;
  if (definition == null) {
    return {
      fields: emptyFields,
      identity: identities.pop()
    };
  }
  if ((definition != null) && !_.isString(definition)) {
    throw new TypeError('optionally expected string in second argument');
  }
  fields = [];
  while (match = fieldsRx.exec(definition)) {
    if (!~(fast.indexOf(fields, field = match[1]))) {
      fields.push(field);
    }
  }
  Object.freeze(fields);
  if (identityMatch = definition.match(identityRx)) {
    identity = Number(identityMatch[1]);
    if (!~(idx = fast.indexOf(identities, identity))) {
      throw new Error('invalid identity specified for component: ' + identity);
    }
    identities.splice(idx, 1);
  } else {
    identity = identities.pop();
  }
  return {
    fields: fields,
    identity: identity
  };
};

Component.disposed = NoMe(function() {
  var data;
  if (!(data = this[bData])) {
    return;
  }
  data.length = 0;
  delete this[symbols.bChanged];
  return this[symbols.bType][bPool].push(this);
});

basePrototype = {
  toString: function() {
    var data;
    return this[symbols.bType].toString() + ((data = this[bData]) ? JSON.stringify(data) : "");
  }
};

basePrototype[symbols.bDispose] = Component.disposed;

createDataProperty = function(i) {
  return {
    enumerable: true,
    get: function() {
      var val;
      if (void 0 !== (val = this[bData][i])) {
        return val;
      } else {
        return null;
      }
    },
    set: function(val) {
      this[symbols.bChanged] = Date.now();
      return this[bData][i] = val;
    }
  };
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

if (process.env.NODE_ENV === 'test') {
  Component.identities = identities;
}

Object.freeze(basePrototype);

module.exports = Object.freeze(Component);
