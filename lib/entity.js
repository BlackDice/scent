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
* Version: 0.0.4
*/
'use strict';
var Entity, Map, NoMe, Symbol, bEntity, bEntityChanged, bList, disposeComponent, entityPool, entityProps, entityPrototype, hasOtherEntity, lill, log, symbols, validateComponent, validateComponentType, _, _ref;

log = (require('debug'))('scent:entity');

_ = require('lodash');

lill = require('lill');

NoMe = require('nome');

_ref = require('./es6-support'), Symbol = _ref.Symbol, Map = _ref.Map;

symbols = require('./symbols');

bEntity = Symbol('represent entity reference on the component');

bList = Symbol('map of components in the entity');

bEntityChanged = Symbol('timestamp of change of component list');

entityPool = lill.attach({});

Entity = function(components) {
  var entity;
  if (components && !_.isArray(components)) {
    throw new TypeError('expected array of components for entity');
  }
  if (entity = lill.getTail(entityPool)) {
    lill.remove(entityPool, entity);
  } else {
    entity = Object.create(entityPrototype, entityProps);
    entity[bList] = new Map;
    entity[symbols.bDispose] = Entity.disposed;
    entity[symbols.bNodes] = new Map;
  }
  if (components != null) {
    components.forEach(entity.add, entity);
  }
  return entity;
};

entityProps = {
  'size': {
    get: function() {
      return this[bList].size;
    }
  }
};

entityPrototype = {
  add: function(component) {
    var componentType;
    validateComponent(component);
    if (hasOtherEntity(component, this)) {
      return this;
    }
    if (this[bList].has(componentType = component[symbols.bType])) {
      log('entity already contains component `%s`, consider using replace method if this is intended', component[symbols.bName]);
    }
    Entity.componentAdded.call(this, component);
    return this;
  },
  replace: function(component) {
    var currentComponent;
    validateComponent(component);
    if (hasOtherEntity(component, this)) {
      return this;
    }
    if (currentComponent = this[bList].get(component[symbols.bType])) {
      delete currentComponent[bEntity];
    }
    Entity.componentAdded.call(this, component);
    return this;
  },
  has: function(componentType) {
    return this[bList].has(componentType);
  },
  get: function(componentType) {
    return this[bList].get(componentType) || null;
  },
  remove: function(componentType, dispose) {
    var component;
    if (false !== dispose && (component = this[bList].get(componentType))) {
      disposeComponent(component);
    }
    return Entity.componentRemoved.call(this, componentType);
  }
};

Object.defineProperty(entityPrototype, symbols.bChanged, {
  get: function() {
    var changed, components, entry;
    if (!(changed = this[bEntityChanged])) {
      return 0;
    }
    components = this[bList].values();
    entry = components.next();
    while (!entry.done) {
      changed = Math.max(changed, entry.value[symbols.bChanged]);
      entry = components.next();
    }
    return changed;
  }
});

Entity.componentAdded = NoMe(function(component) {
  component[bEntity] = this;
  this[bList].set(component[symbols.bType], component);
  this[bEntityChanged] = Date.now();
  return this;
});

Entity.componentRemoved = NoMe(function(componentType) {
  var _ref1;
  if ((_ref1 = this[bList].get(componentType)) != null) {
    delete _ref1[bEntity];
  }
  if (this[bList]["delete"](componentType)) {
    this[bEntityChanged] = Date.now();
  }
  return this;
});

Entity.disposed = NoMe(function() {
  this[bList].forEach(disposeComponent);
  this[bList].clear();
  delete this[bEntityChanged];
  lill.add(entityPool, this);
  return this;
});

(require('./component')).disposed[NoMe.bNotify](function() {
  var entity;
  if (entity = this[bEntity]) {
    entity.remove(this[symbols.bType]);
    return delete this[bEntity];
  }
});

hasOtherEntity = function(component, entity) {
  var inEntity, result;
  if (result = inEntity = component[bEntity] && inEntity !== entity) {
    log('component %s cannot be shared with multiple entities', component);
  }
  return result;
};

disposeComponent = function(component) {
  delete component[bEntity];
  return component[symbols.bDispose]();
};

validateComponent = function(component) {
  if (!component) {
    throw new TypeError('missing component for entity');
  }
  return validateComponentType(component[symbols.bType]);
};

validateComponentType = function(componentType) {
  if (!(_.isFunction(componentType) && componentType[symbols.bIdentity])) {
    throw new TypeError('invalid component type for entity');
  }
};

Object.freeze(Entity);

module.exports = Entity;
