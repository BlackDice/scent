'use strict';
var Component, Entity, Map, NoMe, Symbol, arrayPool, bComponentChanged, bComponents, bDisposedComponents, bEntity, bSetup, componentIsShared, entityPool, fast, log, poolArray, releaseComponent, symbols, validateComponent, validateComponentType, _, _ref;

log = (require('debug'))('scent:entity');

_ = require('lodash');

NoMe = require('nome');

fast = require('fast.js');

_ref = require('es6'), Symbol = _ref.Symbol, Map = _ref.Map;

Component = require('./component');

symbols = require('./symbols');

bEntity = Symbol('represent entity reference on the component');

bComponents = Symbol('map of components in the entity');

bSetup = Symbol('private setup method for entity');

bComponentChanged = Symbol('timestamp of change of component list');

bDisposedComponents = Symbol('list of disposed components');

Entity = function(components) {
  var entity;
  entity = this;
  if (!(entity instanceof Entity)) {
    entity = new Entity;
  }
  entity[bComponents] = new Map;
  entity[bSetup](components);
  return entity;
};

Entity.prototype.add = function(component) {
  var componentType;
  validateComponent(component);
  if (componentIsShared(component, this)) {
    return this;
  }
  if (this.has(componentType = component[symbols.bType])) {
    log('entity already contains component `%s`, consider using replace method if this is intended', componentType.typeName);
    log((new Error).stack);
    return this;
  }
  Entity.componentAdded.call(this, component);
  return this;
};

Entity.prototype.remove = function(componentType) {
  validateComponentType(componentType);
  return Entity.componentRemoved.call(this, componentType);
};

Entity.prototype.replace = function(component) {
  validateComponent(component);
  if (componentIsShared(component, this)) {
    return this;
  }
  this.remove(component[symbols.bType]);
  Entity.componentAdded.call(this, component);
  return this;
};

Entity.prototype.has = function(componentType, allowDisposed) {
  validateComponentType(componentType);
  if (!this[bComponents].has(componentType)) {
    return false;
  }
  return this.get(componentType, allowDisposed) !== null;
};

Entity.prototype.get = function(componentType, allowDisposed) {
  var component;
  validateComponentType(componentType);
  if (!(component = this[bComponents].get(componentType))) {
    return null;
  }
  if (component[symbols.bDisposing]) {
    if (allowDisposed === true) {
      return component;
    } else {
      return null;
    }
  }
  return component;
};

Object.defineProperty(Entity.prototype, 'size', {
  enumerable: true,
  get: function() {
    return this[bComponents].size;
  }
});

Object.defineProperty(Entity.prototype, 'changed', {
  enumerable: true,
  get: function() {
    var changed, components, entry;
    if (!(changed = this[bComponentChanged])) {
      return 0;
    }
    components = this[bComponents].values();
    entry = components.next();
    while (!entry.done) {
      changed = Math.max(changed, entry.value[symbols.bChanged]);
      entry = components.next();
    }
    return changed;
  }
});

Entity.componentAdded = NoMe(function(component) {
  if (this[symbols.bDisposing]) {
    log('component cannot be added when entity is being disposed (since %d)', this[symbols.bDisposing]);
    log((new Error).stack);
    return;
  }
  component[bEntity] = this;
  this[bComponents].set(component[symbols.bType], component);
  this[bComponentChanged] = Date.now();
  return this;
});

Entity.componentRemoved = NoMe(function(componentType) {
  var component;
  if (this[symbols.bDisposing]) {
    log('component cannot be removed when entity is being disposed (since %d)', this[symbols.bDisposing]);
    log((new Error).stack);
    return;
  }
  if (component = this[bComponents].get(componentType)) {
    component[symbols.bDispose]();
    this[bComponentChanged] = Date.now();
  }
  return this;
});

entityPool = [];

Entity.pooled = function(components) {
  var entity;
  if (!entityPool.length) {
    return new Entity(components);
  }
  entity = entityPool.pop();
  entity[bSetup](components);
  return entity;
};

Entity.disposed = NoMe(function() {
  var componentEntry, components, _results;
  this[symbols.bDisposing] = Date.now();
  components = this[bComponents].values();
  componentEntry = components.next();
  _results = [];
  while (!componentEntry.done) {
    componentEntry.value[symbols.bDispose]();
    _results.push(componentEntry = components.next());
  }
  return _results;
});

Entity.prototype.dispose = Entity.disposed;

Component.disposed.notify(function() {
  var entity, list;
  if (!(entity = this[bEntity])) {
    return;
  }
  if (entity[symbols.bDisposing]) {
    return;
  }
  if (!(list = entity[bDisposedComponents])) {
    list = entity[bDisposedComponents] = poolArray();
  }
  return list.push(this);
});

Entity.prototype.release = function() {
  var cList, component, componentType, dList, _i, _len;
  cList = this[bComponents];
  if (dList = this[bDisposedComponents]) {
    for (_i = 0, _len = dList.length; _i < _len; _i++) {
      component = dList[_i];
      if (!releaseComponent(component)) {
        continue;
      }
      componentType = component[symbols.bType];
      if (component !== cList.get(componentType)) {
        continue;
      }
      cList["delete"](componentType);
    }
    dList.length = 0;
    poolArray(dList);
    this[bDisposedComponents] = null;
  }
  if (this[symbols.bDisposing]) {
    this[bComponents].forEach(releaseComponent);
    this[bComponents].clear();
    delete this[bComponentChanged];
    delete this[symbols.bDisposing];
    entityPool.push(this);
    return true;
  }
  return false;
};

Entity.getAll = function(result) {
  var components, entry;
  if (result == null) {
    result = [];
  }
  if (!(this instanceof Entity)) {
    throw new TypeError('expected entity instance for the context');
  }
  components = this[bComponents].values();
  entry = components.next();
  while (!entry.done) {
    result.push(entry.value);
    entry = components.next();
  }
  return result;
};

componentIsShared = function(component, entity) {
  var inEntity, result;
  if (result = inEntity = component[bEntity] && inEntity !== entity) {
    log('component %s cannot be shared with multiple entities', component);
    log((new Error).stack);
  }
  return result;
};

releaseComponent = function(component) {
  var released;
  released = component[symbols.bRelease]();
  if (released) {
    delete component[bEntity];
  }
  return released;
};

validateComponent = function(component) {
  if (!component) {
    throw new TypeError('missing component for entity');
  }
  return validateComponentType(component[symbols.bType]);
};

validateComponentType = function(componentType) {
  if (!(componentType instanceof Component)) {
    throw new TypeError('invalid component type for entity');
  }
};

Entity.prototype[bSetup] = function(components) {
  if (components && !(components instanceof Array)) {
    throw new TypeError('expected array of components for entity');
  }
  if (components) {
    fast.forEach(components, this.add, this);
  }
};

Entity.prototype.inspect = function() {
  var component, components, dList, entry, result, resultList, _i, _len;
  result = {
    "--changed": this.changed
  };
  if (this[symbols.bDisposing]) {
    result['--disposing'] = this[symbols.bDisposing];
  }
  if (dList = this[bDisposedComponents]) {
    result['--disposedComponents'] = resultList = [];
    for (_i = 0, _len = dList.length; _i < _len; _i++) {
      component = dList[_i];
      resultList.push(component.inspect());
    }
  }
  components = this[bComponents].values();
  entry = components.next();
  while (!entry.done) {
    component = entry.value;
    result[component[symbols.bName]] = component.inspect();
    entry = components.next();
  }
  return result;
};

arrayPool = [];

poolArray = function(add) {
  if (add) {
    return arrayPool.push(add);
  }
  if (!arrayPool.length) {
    return [];
  }
  return arrayPool.pop();
};

Entity.prototype[symbols.bDispose] = function() {
  log('using symbol bDispose is deprecated, use direct `dispose` method instead');
  log((new Error).stack);
  return this.dispose();
};

Object.defineProperty(Entity.prototype, symbols.bChanged, {
  get: function() {
    log('using bChanged symbol for entity is DEPRECATED, use direct changed property');
    log((new Error).stack);
    return this.changed;
  }
});

module.exports = Object.freeze(Entity);
