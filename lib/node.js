'use strict';
var Lill, Map, Node, NodeList, NodeListProps, Symbol, bDispose, bList, bPool, bType, fast, hashComponent, log, symbols, validateComponentType, validateEntity, validateStorageMap, _, _ref;

log = (require('debug'))('scent:node');

_ = require('lodash');

fast = require('fast.js');

_ref = require('es6'), Symbol = _ref.Symbol, Map = _ref.Map;

Lill = require('lill');

symbols = require('./symbols');

bDispose = symbols.bDispose, bType = symbols.bType;

bList = Symbol('list of components required by node');

bPool = Symbol('pool of disposed nodes ready to use');

Node = function(componentTypes, storageMap) {
  var hash, nodeList;
  if (!_.isArray(componentTypes)) {
    componentTypes = [componentTypes];
  }
  componentTypes = _(componentTypes).uniq().filter(validateComponentType).value();
  if (!componentTypes.length) {
    throw new TypeError('require at least one component for node');
  }
  if (storageMap && !validateStorageMap(storageMap)) {
    throw new TypeError('valid storage map expected in second argument');
  }
  hash = fast.reduce(componentTypes, hashComponent, 1);
  if (storageMap && (nodeList = storageMap.get(hash))) {
    return nodeList;
  }
  nodeList = Object.create(NodeList, NodeListProps);
  nodeList[bList] = componentTypes;
  nodeList[bPool] = [];
  Lill.attach(nodeList);
  if (storageMap) {
    storageMap.set(hash, nodeList);
  }
  Object.freeze(nodeList);
  return nodeList;
};

NodeList = {
  addEntity: function() {
    var component, componentType, entity, map, nodeItem, pool, _i, _len, _ref1;
    entity = validateEntity(arguments[0]);
    map = entity[symbols.bNodes];
    if (map.has(this)) {
      return this;
    }
    if ((pool = this[bPool]).length) {
      nodeItem = pool.pop();
    } else {
      nodeItem = Object.create(null);
      nodeItem[bType] = this;
    }
    _ref1 = this[bList];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      componentType = _ref1[_i];
      if (!(component = entity.get(componentType))) {
        return this;
      }
      nodeItem[componentType[symbols.bName]] = component;
    }
    nodeItem[symbols.bEntity] = entity;
    map.set(this, nodeItem);
    Lill.add(this, nodeItem);
    return this;
  },
  updateEntity: function() {
    var component, componentType, entity, map, nodeItem, _i, _len, _ref1;
    entity = validateEntity(arguments[0]);
    map = entity[symbols.bNodes];
    if (!(nodeItem = map.get(this))) {
      return this.addEntity(entity);
    }
    _ref1 = this[bList];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      componentType = _ref1[_i];
      if (!(component = entity.get(componentType))) {
        return this.removeEntity(entity);
      }
      nodeItem[componentType[symbols.bName]] = component;
    }
    return this;
  },
  removeEntity: function() {
    var entity, map, nodeItem;
    entity = validateEntity(arguments[0]);
    map = entity[symbols.bNodes];
    if (nodeItem = map.get(this)) {
      Lill.remove(this, nodeItem);
      map["delete"](this);
      nodeItem[symbols.bEntity] = null;
      this[bPool].push(nodeItem);
    }
    return this;
  },
  each: function(fn, ctx) {
    return Lill.each(this, fn, ctx);
  }
};

NodeListProps = Object.create(null);

NodeListProps['head'] = {
  enumerable: true,
  get: function() {
    return Lill.getHead(this);
  }
};

NodeListProps['tail'] = {
  enumerable: true,
  get: function() {
    return Lill.getTail(this);
  }
};

NodeListProps['size'] = {
  enumerable: true,
  get: function() {
    return Lill.getSize(this);
  }
};

hashComponent = function(result, componentType) {
  return result *= componentType[symbols.bIdentity];
};

validateEntity = function(entity) {
  if (!(entity && _.isFunction(entity.get))) {
    throw new TypeError('invalid entity for node');
  }
  return entity;
};

validateComponentType = function(componentType) {
  if (!componentType) {
    return false;
  }
  if (!(_.isFunction(componentType) && componentType[symbols.bIdentity])) {
    throw new TypeError('invalid component for node');
  }
  return true;
};

validateStorageMap = function(storageMap) {
  if (!storageMap) {
    return false;
  }
  if (storageMap instanceof Map) {
    return true;
  }
  return _.isFunction(storageMap.get) && _.isFunction(storageMap.set);
};

module.exports = Node;
