/*
* The MIT License (MIT)
* Copyright © 2014 Black Dice Ltd.
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* 
* Version: 0.4.1
*/
!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.scent=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
exports.Component = require('./component');

exports.Entity = require('./entity');

exports.Node = require('./node');

exports.System = require('./system');

exports.Engine = require('./engine');

exports.Symbols = require('./symbols');

},{"./component":2,"./engine":3,"./entity":4,"./node":5,"./symbols":7,"./system":8}],2:[function(require,module,exports){
'use strict';
var Component, Map, NoMe, Set, Symbol, bData, bPool, basePrototype, createDataProperty, emptyFields, fast, fieldsRx, identities, identityRx, initializeData, log, parseDefinition, symbols, verifyName, _, _ref;

log = (require('debug'))('scent:component');

_ = require('lodash');

fast = require('fast.js');

NoMe = require('nome');

_ref = require('es6'), Symbol = _ref.Symbol, Map = _ref.Map, Set = _ref.Set;

symbols = require('./symbols');

bPool = Symbol('pool of disposed components');

bData = Symbol('data array for the component');

identities = fast.clone(require('./primes')).reverse();

fieldsRx = /(?:^|\s)([a-z][a-z0-9]*(?=\s|$))/gi;

identityRx = /(?:^|\s)#([0-9]+(?=\s|$))/i;

Component = function(name, definition) {
  var ComponentType, componentPool, componentPrototype, field, fields, i, identity, toString, _i, _len, _ref1;
  verifyName(name);
  if (definition instanceof Component) {
    return definition;
  }
  _ref1 = parseDefinition(definition), fields = _ref1.fields, identity = _ref1.identity;
  componentPool = [];
  componentPrototype = Object.create(basePrototype);
  for (i = _i = 0, _len = fields.length; _i < _len; i = ++_i) {
    field = fields[i];
    Object.defineProperty(componentPrototype, field, createDataProperty(i));
  }
  ComponentType = function(data) {
    var component;
    component = this;
    if (!(component instanceof ComponentType)) {
      component = new ComponentType(data);
    }
    initializeData(component, fields, data);
    return component;
  };
  ComponentType.prototype = componentPrototype;
  ComponentType[bPool] = componentPool;
  ComponentType[symbols.bFields] = fields;
  ComponentType[symbols.bName] = name;
  ComponentType[symbols.bIdentity] = identity;
  ComponentType[symbols.bDefinition] = "#" + identity + " " + (fields.join(' '));
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

if (typeof IN_TEST !== 'undefined') {
  Component.identities = identities;
}

Object.freeze(basePrototype);

module.exports = Object.freeze(Component);

},{"./primes":6,"./symbols":7,"debug":undefined,"es6":undefined,"fast.js":undefined,"lodash":undefined,"nome":undefined}],3:[function(require,module,exports){
'use strict';
var Engine, Entity, Lill, Map, NoMe, Node, async, fast, fnArgs, log, symbols, _;

log = (require('debug'))('scent:engine');

_ = require('lodash');

fast = require('fast.js');

fnArgs = require('fn-args');

async = require('async');

NoMe = require('nome');

Lill = require('lill');

Map = require('es6').Map;

symbols = require('./symbols');

Node = require('./node');

Entity = require('./entity');

Engine = function(initializer) {
  var engine, getSystemArgs, initializeSystem, initializeSystemAsync, injections, isStarted, nodeMap, nomeAdded, nomeDisposed, nomeRemoved, provide, systemList, updateNodeTypes, updatedEntities;
  if ((initializer != null) && !_.isFunction(initializer)) {
    throw new TypeError('expected function as engine initializer');
  }
  engine = Object.create(null);
  isStarted = false;
  nodeMap = new Map;
  engine.getNodeType = function(componentTypes) {
    return Node(componentTypes, nodeMap);
  };
  engine.entityList = Lill.attach({});
  updatedEntities = Lill.attach({});
  engine.addEntity = function(components) {
    var entity;
    entity = Entity(components);
    Lill.add(engine.entityList, entity);
    Lill.add(updatedEntities, entity);
    return entity;
  };
  systemList = [];
  engine.addSystem = function(systemInitializer) {
    var name;
    if (!(systemInitializer && _.isFunction(systemInitializer))) {
      throw new TypeError('expected function for addSystem call');
    }
    if (~fast.indexOf(systemList, systemInitializer)) {
      throw new Error('system is already added to engine');
    }
    if (!(name = systemInitializer[symbols.bName])) {
      throw new TypeError('function for addSystem is not system initializer');
    }
    fast.forEach(systemList, function(storedSystem) {
      if (storedSystem[symbols.bName] === name) {
        throw new TypeError('name for system has to be unique');
      }
    });
    systemList.push(systemInitializer);
    if (isStarted) {
      initializeSystem(systemInitializer);
    }
    return engine;
  };
  engine.addSystems = function(list) {
    var systemInitializer, _i, _len;
    if (!(list && _.isArray(list))) {
      throw new TypeError('expected array of system initializers');
    }
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      systemInitializer = list[_i];
      engine.addSystem(systemInitializer);
    }
    return engine;
  };
  engine.start = function(done) {
    if ((done != null) && !_.isFunction(done)) {
      throw new TypeError('expected callback function for engine start');
    }
    if (isStarted) {
      throw new Error('engine has been started already');
    }
    if (done) {
      async.each(systemList, initializeSystemAsync, function(err) {
        isStarted = true;
        return done(err);
      });
    } else {
      fast.forEach(systemList, initializeSystem);
      isStarted = true;
    }
    return this;
  };
  engine.update = NoMe(function() {
    var entry, nodeTypes;
    nodeTypes = nodeMap.values();
    entry = nodeTypes.next();
    while (!entry.done) {
      updateNodeTypes(entry.value);
      entry = nodeTypes.next();
    }
    return Lill.clear(updatedEntities);
  });
  engine.onUpdate = fast.bind(engine.update.notify, engine.update);
  nomeDisposed = Entity.disposed.notify(function() {
    Lill.add(updatedEntities, this);
    return Lill.remove(engine.entityList, this);
  });
  nomeAdded = Entity.componentAdded.notify(function() {
    return Lill.add(updatedEntities, this);
  });
  nomeRemoved = Entity.componentRemoved.notify(function() {
    return Lill.add(updatedEntities, this);
  });
  engine[symbols.bDispose] = function() {
    Entity.disposed.denotify(nomeDisposed);
    Entity.componentAdded.denotify(nomeAdded);
    Entity.componentRemoved.denotify(nomeRemoved);
    nodeMap.clear();
    systemList.length = 0;
    injections.clear();
    Lill.detach(updatedEntities);
    return isStarted = false;
  };
  updateNodeTypes = function(nodeType) {
    return Lill.each(updatedEntities, function(entity) {
      return nodeType.updateEntity(entity);
    });
  };
  initializeSystemAsync = function(systemInitializer, cb) {
    var args, handleError;
    handleError = function(fn) {
      var result;
      result = fast["try"](fn);
      return cb(result instanceof Error ? result : null);
    };
    if (!systemInitializer.length) {
      return handleError(function() {
        return systemInitializer.call(null);
      });
    }
    args = getSystemArgs(systemInitializer, cb);
    if (!~fast.indexOf(args, cb)) {
      return handleError(function() {
        return fast.apply(systemInitializer, null, args);
      });
    } else {
      return fast.apply(systemInitializer, null, args);
    }
  };
  initializeSystem = function(systemInitializer) {
    var args, handleError;
    handleError = function(fn) {
      var result;
      result = fast["try"](fn);
      if (result instanceof Error) {
        throw result;
      }
    };
    if (!systemInitializer.length) {
      return handleError(function() {
        return systemInitializer.call(null);
      });
    }
    args = getSystemArgs(systemInitializer);
    return handleError(function() {
      return fast.apply(systemInitializer, null, args);
    });
  };
  getSystemArgs = function(systemInitializer, done) {
    var args;
    args = fnArgs(systemInitializer);
    fast.forEach(args, function(argName, i) {
      var injection;
      if (done && argName === '$done') {
        injection = done;
      } else {
        injection = injections.has(argName) ? injections.get(argName) : null;
        if (_.isFunction(injection)) {
          injection = injection.call(null, engine, systemInitializer);
        }
      }
      return args[i] = injection;
    });
    return args;
  };
  injections = new Map;
  provide = function(name, injection) {
    if (Object.isFrozen(engine)) {
      throw new Error('cannot call provide for initialized engine');
    }
    if (!((name != null ? name.constructor : void 0) === String && name.length)) {
      throw new TypeError('expected injection name for provide call');
    }
    if (injections.has(name)) {
      throw new TypeError('injection of that name is already defined');
    }
    if (injection == null) {
      throw new TypeError('expected non-null value for injection');
    }
    injections.set(name, injection);
  };
  provide('$engine', engine);
  if (initializer) {
    initializer.call(null, engine, provide);
    initializer = null;
  }
  Object.setPrototypeOf(engine, Engine.prototype);
  return Object.freeze(engine);
};

Engine.prototype = Object.create(Function.prototype);

Engine.prototype.toString = function() {
  return "Engine (" + (Lill.getSize(this.entityList)) + " entities)";
};

module.exports = Object.freeze(Engine);

},{"./entity":4,"./node":5,"./symbols":7,"async":undefined,"debug":undefined,"es6":undefined,"fast.js":undefined,"fn-args":undefined,"lill":undefined,"lodash":undefined,"nome":undefined}],4:[function(require,module,exports){
'use strict';
var Entity, Lill, Map, NoMe, Symbol, bEntity, bEntityChanged, bList, disposeComponent, entityPool, entityProps, entityPrototype, hasOtherEntity, log, symbols, validateComponent, validateComponentType, _, _ref;

log = (require('debug'))('scent:entity');

_ = require('lodash');

Lill = require('lill');

NoMe = require('nome');

_ref = require('es6'), Symbol = _ref.Symbol, Map = _ref.Map;

symbols = require('./symbols');

bEntity = Symbol('represent entity reference on the component');

bList = Symbol('map of components in the entity');

bEntityChanged = Symbol('timestamp of change of component list');

entityPool = Lill.attach({});

Entity = function(components) {
  var entity;
  if (components && !_.isArray(components)) {
    throw new TypeError('expected array of components for entity');
  }
  if (entity = Lill.getTail(entityPool)) {
    Lill.remove(entityPool, entity);
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
  getAll: function(result) {
    var components, entry;
    if (result == null) {
      result = [];
    }
    components = this[bList].values();
    entry = components.next();
    while (!entry.done) {
      result.push(entry.value);
      entry = components.next();
    }
    return result;
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
  Lill.add(entityPool, this);
  return this;
});

(require('./component')).disposed.notify(function() {
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

Entity.prototype = Object.create(Function.prototype);

Entity.prototype.toString = function() {
  return "Entity (" + this.size + " components)";
};

Object.setPrototypeOf(entityPrototype, Entity.prototype);

Object.freeze(Entity);

module.exports = Entity;

},{"./component":2,"./symbols":7,"debug":undefined,"es6":undefined,"lill":undefined,"lodash":undefined,"nome":undefined}],5:[function(require,module,exports){
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

},{"./symbols":7,"debug":undefined,"es6":undefined,"fast.js":undefined,"lill":undefined,"lodash":undefined}],6:[function(require,module,exports){
module.exports = Object.freeze([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701, 709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811, 821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997, 1009, 1013, 1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063, 1069, 1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129, 1151, 1153, 1163, 1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223, 1229, 1231, 1237, 1249, 1259, 1277, 1279, 1283, 1289, 1291, 1297, 1301, 1303, 1307, 1319, 1321, 1327, 1361, 1367, 1373, 1381, 1399, 1409, 1423, 1427, 1429, 1433, 1439, 1447, 1451, 1453, 1459, 1471, 1481, 1483, 1487, 1489, 1493, 1499, 1511, 1523, 1531, 1543, 1549, 1553, 1559, 1567, 1571, 1579, 1583, 1597, 1601, 1607, 1609, 1613, 1619, 1621, 1627, 1637, 1657, 1663, 1667, 1669, 1693, 1697, 1699, 1709, 1721, 1723, 1733, 1741, 1747, 1753, 1759, 1777, 1783, 1787, 1789, 1801, 1811, 1823, 1831, 1847, 1861, 1867, 1871, 1873, 1877, 1879, 1889, 1901, 1907, 1913, 1931, 1933, 1949, 1951, 1973, 1979, 1987, 1993, 1997, 1999, 2003, 2011, 2017, 2027, 2029, 2039, 2053, 2063, 2069, 2081, 2083, 2087, 2089, 2099, 2111, 2113, 2129, 2131, 2137, 2141, 2143, 2153, 2161, 2179, 2203, 2207, 2213, 2221, 2237, 2239, 2243, 2251, 2267, 2269, 2273, 2281, 2287, 2293, 2297, 2309, 2311, 2333, 2339, 2341, 2347, 2351, 2357, 2371, 2377, 2381, 2383, 2389, 2393, 2399, 2411, 2417, 2423, 2437, 2441, 2447, 2459, 2467, 2473, 2477, 2503, 2521, 2531, 2539, 2543, 2549, 2551, 2557, 2579, 2591, 2593, 2609, 2617, 2621, 2633, 2647, 2657, 2659, 2663, 2671, 2677, 2683, 2687, 2689, 2693, 2699, 2707, 2711, 2713, 2719, 2729, 2731, 2741, 2749, 2753, 2767, 2777, 2789, 2791, 2797, 2801, 2803, 2819, 2833, 2837, 2843, 2851, 2857, 2861, 2879, 2887, 2897, 2903, 2909, 2917, 2927, 2939, 2953, 2957, 2963, 2969, 2971, 2999, 3001, 3011, 3019, 3023, 3037, 3041, 3049, 3061, 3067, 3079, 3083, 3089, 3109, 3119, 3121, 3137, 3163, 3167, 3169, 3181, 3187, 3191, 3203, 3209, 3217, 3221, 3229, 3251, 3253, 3257, 3259, 3271, 3299, 3301, 3307, 3313, 3319, 3323, 3329, 3331, 3343, 3347, 3359, 3361, 3371, 3373, 3389, 3391, 3407, 3413, 3433, 3449, 3457, 3461, 3463, 3467, 3469, 3491, 3499, 3511, 3517, 3527, 3529, 3533, 3539, 3541, 3547, 3557, 3559, 3571, 3581, 3583, 3593, 3607, 3613, 3617, 3623, 3631, 3637, 3643, 3659, 3671, 3673, 3677, 3691, 3697, 3701, 3709, 3719, 3727, 3733, 3739, 3761, 3767, 3769, 3779, 3793, 3797, 3803, 3821, 3823, 3833, 3847, 3851, 3853, 3863, 3877, 3881, 3889, 3907, 3911, 3917, 3919, 3923, 3929, 3931, 3943, 3947, 3967, 3989, 4001, 4003, 4007, 4013, 4019, 4021, 4027, 4049, 4051, 4057, 4073, 4079, 4091, 4093, 4099, 4111, 4127, 4129, 4133, 4139, 4153, 4157, 4159, 4177, 4201, 4211, 4217, 4219, 4229, 4231, 4241, 4243, 4253, 4259, 4261, 4271, 4273, 4283, 4289, 4297, 4327, 4337, 4339, 4349, 4357, 4363, 4373, 4391, 4397, 4409, 4421, 4423, 4441, 4447, 4451, 4457, 4463, 4481, 4483, 4493, 4507, 4513, 4517, 4519, 4523, 4547, 4549, 4561, 4567, 4583, 4591, 4597, 4603, 4621, 4637, 4639, 4643, 4649, 4651, 4657, 4663, 4673, 4679, 4691, 4703, 4721, 4723, 4729, 4733, 4751, 4759, 4783, 4787, 4789, 4793, 4799, 4801, 4813, 4817, 4831, 4861, 4871, 4877, 4889, 4903, 4909, 4919, 4931, 4933, 4937, 4943, 4951, 4957, 4967, 4969, 4973, 4987, 4993, 4999, 5003, 5009, 5011, 5021, 5023, 5039, 5051, 5059, 5077, 5081, 5087, 5099, 5101, 5107, 5113, 5119, 5147, 5153, 5167, 5171, 5179, 5189, 5197, 5209, 5227, 5231, 5233, 5237, 5261, 5273, 5279, 5281, 5297, 5303, 5309, 5323, 5333, 5347, 5351, 5381, 5387, 5393, 5399, 5407, 5413, 5417, 5419, 5431, 5437, 5441, 5443, 5449, 5471, 5477, 5479, 5483, 5501, 5503, 5507, 5519, 5521, 5527, 5531, 5557, 5563, 5569, 5573, 5581, 5591, 5623, 5639, 5641, 5647, 5651, 5653, 5657, 5659, 5669, 5683, 5689, 5693, 5701, 5711, 5717, 5737, 5741, 5743, 5749, 5779, 5783, 5791, 5801, 5807, 5813, 5821, 5827, 5839, 5843, 5849, 5851, 5857, 5861, 5867, 5869, 5879, 5881, 5897, 5903, 5923, 5927, 5939, 5953, 5981, 5987, 6007, 6011, 6029, 6037, 6043, 6047, 6053, 6067, 6073, 6079, 6089, 6091, 6101, 6113, 6121, 6131, 6133, 6143, 6151, 6163, 6173, 6197, 6199, 6203, 6211, 6217, 6221, 6229, 6247, 6257, 6263, 6269, 6271, 6277, 6287, 6299, 6301, 6311, 6317, 6323, 6329, 6337, 6343, 6353, 6359, 6361, 6367, 6373, 6379, 6389, 6397, 6421, 6427, 6449, 6451, 6469, 6473, 6481, 6491, 6521, 6529, 6547, 6551, 6553, 6563, 6569, 6571, 6577, 6581, 6599, 6607, 6619, 6637, 6653, 6659, 6661, 6673, 6679, 6689, 6691, 6701, 6703, 6709, 6719, 6733, 6737, 6761, 6763, 6779, 6781, 6791, 6793, 6803, 6823, 6827, 6829, 6833, 6841, 6857, 6863, 6869, 6871, 6883, 6899, 6907, 6911, 6917, 6947, 6949, 6959, 6961, 6967, 6971, 6977, 6983, 6991, 6997, 7001, 7013, 7019, 7027, 7039, 7043, 7057, 7069, 7079, 7103, 7109, 7121, 7127, 7129, 7151, 7159, 7177, 7187, 7193, 7207, 7211, 7213, 7219, 7229, 7237, 7243, 7247, 7253, 7283, 7297, 7307, 7309, 7321, 7331, 7333, 7349, 7351, 7369, 7393, 7411, 7417, 7433, 7451, 7457, 7459, 7477, 7481, 7487, 7489, 7499, 7507, 7517, 7523, 7529, 7537, 7541, 7547, 7549, 7559, 7561, 7573, 7577, 7583, 7589, 7591, 7603, 7607, 7621, 7639, 7643, 7649, 7669, 7673, 7681, 7687, 7691, 7699, 7703, 7717, 7723, 7727, 7741, 7753, 7757, 7759, 7789, 7793, 7817, 7823, 7829, 7841, 7853, 7867, 7873, 7877, 7879, 7883, 7901, 7907, 7919]);

},{}],7:[function(require,module,exports){
'use strict';
var Symbol;

Symbol = require('es6').Symbol;

exports.bName = Symbol('name of the object');

exports.bType = Symbol('type of the object');

exports.bDispose = Symbol('method to dispose object');

exports.bChanged = Symbol('timestamp of last change');

exports.bIdentity = Symbol('identifier of the object');

exports.bFields = Symbol('fields defined for the component');

exports.bDefinition = Symbol('definition of the component');

exports.bNodes = Symbol('nodes that owns entity');

exports.bEntity = Symbol('reference to entity instance');

exports.Symbol = Symbol;

},{"es6":undefined}],8:[function(require,module,exports){
var symbols, _;

_ = require('lodash');

symbols = require('./symbols');

module.exports = function(name, initializer) {
  if (!_.isString(name)) {
    throw new TypeError('expected name for system');
  }
  if (!_.isFunction(initializer)) {
    throw new TypeError('expected function as system initializer');
  }
  initializer[symbols.bName] = name;
  return Object.freeze(initializer);
};

},{"./symbols":7,"lodash":undefined}]},{},[1])(1)
});