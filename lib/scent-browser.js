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
* Version: 0.7.2
*/
!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.scent=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
exports.Component = require('./component');

exports.Entity = require('./entity');

exports.Node = require('./node');

exports.System = require('./system');

exports.Engine = require('./engine');

exports.Symbols = require('./symbols');

},{"./component":3,"./engine":4,"./entity":5,"./node":6,"./symbols":8,"./system":9}],2:[function(require,module,exports){
'use strict';
var Action, ActionType, Entity, Symbol, bData, bPool, each$noContext, each$withContext, fast, listPool, log, poolAction, poolList, symbols, _;

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

Action = function(type, data, meta) {
  this.type = type;
  this.data = data;
  this.meta = meta;
};

Action.prototype = Object.create(Array.prototype);

Action.prototype.time = 0;

Action.prototype.type = null;

Action.prototype.data = null;

Action.prototype.meta = null;

Action.prototype.get = function(prop) {
  var _ref;
  return (_ref = this.data) != null ? _ref[prop] : void 0;
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
  var action, data, fn, _i, _len, _ref, _ref1;
  if (!(iterator && _.isFunction(iterator))) {
    throw new TypeError('expected iterator function for the each call');
  }
  data = this[bData];
  if (data.buffer == null) {
    data.buffer = poolList();
  }
  if (!((_ref = data.list) != null ? _ref.length : void 0)) {
    return;
  }
  fn = ctx ? each$withContext : each$noContext;
  _ref1 = data.list;
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    action = _ref1[_i];
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
  var action, data, _i, _len, _ref;
  data = this[bData];
  if (data.list) {
    _ref = data.list;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      action = _ref[_i];
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

},{"./entity":5,"./symbols":8,"debug":undefined,"es6":undefined,"fast.js":undefined,"lodash":undefined}],3:[function(require,module,exports){
'use strict';
var BaseComponent, Component, Map, NoMe, Set, Symbol, bData, bPool, bSetup, defineFieldProperty, emptyFields, fast, fieldsRx, identities, identityRx, initializeData, log, poolMap, symbols, _, _ref;

log = (require('debug'))('scent:component');

_ = require('lodash');

fast = require('fast.js');

NoMe = require('nome');

_ref = require('es6'), Symbol = _ref.Symbol, Map = _ref.Map, Set = _ref.Set;

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
  var field, i, _i, _len, _ref1;
  this[symbols.bName] = name;
  this[bSetup](definition);
  _ref1 = this[symbols.bFields];
  for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
    field = _ref1[i];
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
  var field, result, _i, _len, _ref1;
  result = {
    "--typeName": this[symbols.bName],
    "--typeIdentity": this[symbols.bIdentity],
    "--changed": this[symbols.bChanged]
  };
  if (this[symbols.bDisposing]) {
    result['--disposing'] = this[symbols.bDisposing];
  }
  _ref1 = this[symbols.bFields];
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    field = _ref1[_i];
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

},{"./primes":7,"./symbols":8,"debug":undefined,"es6":undefined,"fast.js":undefined,"lodash":undefined,"nome":undefined}],4:[function(require,module,exports){
'use strict';
var Action, Engine, Entity, Lill, Map, NoMe, Node, async, fast, fnArgs, log, symbols, _;

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

Action = require('./action');

Engine = function(initializer) {
  var actionHandlerMap, actionMap, actionTypes, addedEntities, disposedEntities, engine, finishNodeType, getSystemArgs, hashComponent, initializeSystem, initializeSystemAsync, injections, isStarted, nodeMap, nodeTypes, nomeComponentAdded, nomeComponentRemoved, nomeEntityDisposed, processActionType, processActions, processNodeTypes, provide, releasedEntities, systemAnonCounter, systemList, updateNodeType, updatedEntities;
  if ((initializer != null) && !_.isFunction(initializer)) {
    throw new TypeError('expected function as engine initializer');
  }
  engine = Object.create(null);
  isStarted = false;
  engine.entityList = Lill.attach({});
  engine.addEntity = function(components) {
    var entity;
    entity = Entity(components);
    Lill.add(engine.entityList, entity);
    addedEntities.push(entity);
    return entity;
  };
  Object.defineProperty(engine, 'size', {
    get: function() {
      return Lill.getSize(engine.entityList);
    }
  });
  systemList = [];
  systemAnonCounter = 1;
  engine.addSystem = function(systemInitializer) {
    var name;
    if (!(systemInitializer && _.isFunction(systemInitializer))) {
      throw new TypeError('expected function for addSystem call');
    }
    if (~fast.indexOf(systemList, systemInitializer)) {
      throw new Error('system is already added to engine');
    }
    name = systemInitializer[symbols.bName];
    if (!name) {
      name = systemInitializer.name || systemInitializer.displayName || 'system' + (systemAnonCounter++);
      systemInitializer[symbols.bName] = name;
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
    processActions();
    return processNodeTypes();
  });
  engine.onUpdate = fast.bind(engine.update.notify, engine.update);
  nodeMap = {};
  nodeTypes = Lill.attach({});
  engine.getNodeType = function(componentTypes) {
    var hash, nodeType, validTypes;
    validTypes = Node.validateComponentTypes(componentTypes);
    if (!(validTypes != null ? validTypes.length : void 0)) {
      throw new TypeError('specify at least one component type to getNodeType');
    }
    hash = fast.reduce(validTypes, hashComponent, 1);
    if (nodeType = nodeMap[hash]) {
      return nodeType;
    }
    nodeType = new Node(componentTypes);
    nodeMap[hash] = nodeType;
    Lill.add(nodeTypes, nodeType);
    return nodeType;
  };
  hashComponent = function(result, componentType) {
    return result *= componentType.typeIdentity;
  };
  addedEntities = [];
  updatedEntities = [];
  disposedEntities = [];
  processNodeTypes = function() {
    var entity, _i, _len;
    updateNodeType(Node.prototype.addEntity, addedEntities);
    updateNodeType(Node.prototype.removeEntity, disposedEntities);
    updateNodeType(Node.prototype.updateEntity, updatedEntities);
    Lill.each(nodeTypes, finishNodeType);
    if (addedEntities.length || disposedEntities.length || updatedEntities.length) {
      return processNodeTypes();
    }
    for (_i = 0, _len = releasedEntities.length; _i < _len; _i++) {
      entity = releasedEntities[_i];
      entity.release();
    }
    releasedEntities.length = 0;
  };
  releasedEntities = [];
  finishNodeType = function(nodeType) {
    return nodeType.finish();
  };
  updateNodeType = function(nodeMethod, entities) {
    var entity, execMethod, _i, _len;
    if (!entities.length) {
      return;
    }
    execMethod = function(nodeType) {
      return nodeMethod.call(nodeType, this);
    };
    for (_i = 0, _len = entities.length; _i < _len; _i++) {
      entity = entities[_i];
      Lill.each(nodeTypes, execMethod, entity);
      releasedEntities.push(entity);
    }
    entities.length = 0;
  };
  nomeEntityDisposed = Entity.disposed.notify(function() {
    var idx;
    if (!Lill.has(engine.entityList, this)) {
      return;
    }
    if (~(idx = addedEntities.indexOf(this))) {
      addedEntities.splice(idx, 1);
    }
    if (~(idx = updatedEntities.indexOf(this))) {
      updatedEntities.splice(idx, 1);
    }
    disposedEntities.push(this);
    return Lill.remove(engine.entityList, this);
  });
  nomeComponentAdded = Entity.componentAdded.notify(function() {
    if (!Lill.has(engine.entityList, this)) {
      return;
    }
    if (!(~(addedEntities.indexOf(this)) || ~(updatedEntities.indexOf(this)))) {
      return updatedEntities.push(this);
    }
  });
  nomeComponentRemoved = Entity.componentRemoved.notify(function() {
    if (!Lill.has(engine.entityList, this)) {
      return;
    }
    if (!(~(addedEntities.indexOf(this)) || ~(updatedEntities.indexOf(this)))) {
      return updatedEntities.push(this);
    }
  });
  actionMap = new Map;
  actionHandlerMap = new Map;
  actionTypes = Lill.attach({});
  engine.getActionType = function(actionName, noCreate) {
    var actionType;
    if (!(actionType = actionMap.get(actionName))) {
      if (noCreate === true) {
        return null;
      }
      actionType = new Action(actionName);
      actionMap.set(actionName, actionType);
      Lill.add(actionTypes, actionType);
    }
    return actionType;
  };
  engine.triggerAction = function(actionName, data, meta) {
    var actionType;
    actionType = engine.getActionType(actionName);
    if (!actionHandlerMap.has(actionType)) {
      log("Action `%s` cannot be triggered. Use onAction method to add handler first.", actionName);
      return engine;
    }
    actionType.trigger(data, meta);
    return engine;
  };
  engine.onAction = function(actionName, callback) {
    var actionType, map;
    if (!_.isString(actionName)) {
      throw new TypeError('expected name of action for onAction call');
    }
    if (!_.isFunction(callback)) {
      throw new TypeError('expected callback function for onAction call');
    }
    actionType = engine.getActionType(actionName);
    if (!(map = actionHandlerMap.get(actionType))) {
      map = [callback];
      actionHandlerMap.set(actionType, map);
    } else {
      map.push(callback);
    }
    return engine;
  };
  processActions = function() {
    return Lill.each(actionTypes, processActionType);
  };
  processActionType = function(actionType) {
    var callback, callbacks, _i, _len;
    callbacks = actionHandlerMap.get(actionType);
    if (!(callbacks && callbacks.length)) {
      return;
    }
    for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
      callback = callbacks[_i];
      actionType.each(callback);
    }
    return actionType.finish();
  };
  engine[symbols.bDispose] = function() {
    Entity.disposed.denotify(nomeEntityDisposed);
    Entity.componentAdded.denotify(nomeComponentAdded);
    Entity.componentRemoved.denotify(nomeComponentRemoved);
    nodeTypes.length = 0;
    systemList.length = 0;
    injections.clear();
    Lill.detach(actionTypes);
    actionMap.clear();
    actionHandlerMap.clear();
    addedEntities.length = 0;
    updatedEntities.length = 0;
    disposedEntities.length = 0;
    return isStarted = false;
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

},{"./action":2,"./entity":5,"./node":6,"./symbols":8,"async":undefined,"debug":undefined,"es6":undefined,"fast.js":undefined,"fn-args":undefined,"lill":undefined,"lodash":undefined,"nome":undefined}],5:[function(require,module,exports){
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

},{"./component":3,"./symbols":8,"debug":undefined,"es6":undefined,"fast.js":undefined,"lodash":undefined,"nome":undefined}],6:[function(require,module,exports){
'use strict';
var BaseNodeItem, Component, Lill, Map, NodeType, Symbol, bData, bType, createNodeItem, defineComponentProperty, fast, log, mapComponentName, poolNodeItem, symbols, validateComponentType, validateEntity, _, _ref,
  __slice = [].slice;

log = (require('debug'))('scent:node');

_ = require('lodash');

fast = require('fast.js');

Lill = require('lill');

_ref = require('es6'), Symbol = _ref.Symbol, Map = _ref.Map;

Component = require('./component');

bType = (symbols = require('./symbols')).bType;

bData = Symbol('internal data for the nodelist');

NodeType = function(componentTypes) {
  if (!(this instanceof NodeType)) {
    return new NodeType(componentTypes);
  }
  componentTypes = NodeType.validateComponentTypes(componentTypes);
  if (!(componentTypes != null ? componentTypes.length : void 0)) {
    throw new TypeError('node type requires at least one component type');
  }
  this[bData] = {
    list: componentTypes,
    item: createNodeItem(this, componentTypes),
    pool: fast.bind(poolNodeItem, null, []),
    ref: Symbol('node(' + componentTypes.map(mapComponentName).join(',') + ')'),
    added: false,
    removed: false
  };
  return Lill.attach(this);
};

NodeType.prototype.entityFits = function(entity) {
  var componentType, _i, _len, _ref1;
  if (entity[symbols.bDisposing]) {
    return false;
  }
  _ref1 = this[bData].list;
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    componentType = _ref1[_i];
    if (!entity.has(componentType)) {
      return false;
    }
  }
  return true;
};

NodeType.prototype.addEntity = function() {
  var added, data, entity, nodeItem;
  data = this[bData];
  entity = validateEntity(arguments[0]);
  if (entity[data.ref] || !this.entityFits(entity)) {
    return this;
  }
  if (!(nodeItem = data.pool())) {
    nodeItem = new data.item;
  }
  nodeItem[symbols.bEntity] = entity;
  entity[data.ref] = nodeItem;
  Lill.add(this, nodeItem);
  if (added = data.added) {
    Lill.add(added, nodeItem);
  }
  return this;
};

NodeType.prototype.removeEntity = function() {
  var data, entity, nodeItem, removed;
  data = this[bData];
  entity = validateEntity(arguments[0]);
  if (!(nodeItem = entity[data.ref])) {
    return this;
  }
  if (this.entityFits(entity)) {
    return this;
  }
  Lill.remove(this, nodeItem);
  delete entity[data.ref];
  if (removed = data.removed) {
    Lill.add(removed, nodeItem);
  } else {
    data.pool(nodeItem);
  }
  return this;
};

NodeType.prototype.updateEntity = function() {
  var data, entity;
  data = this[bData];
  entity = validateEntity(arguments[0]);
  if (!entity[data.ref]) {
    return this.addEntity(entity);
  } else {
    return this.removeEntity(entity);
  }
  return this;
};

NodeType.prototype.each = function(fn) {
  var args;
  if (arguments.length <= 1) {
    Lill.each(this, fn);
    return this;
  }
  args = Array.prototype.slice.call(arguments, 1);
  Lill.each(this, function(node) {
    return fn.apply(null, [node].concat(__slice.call(args)));
  });
  return this;
};

NodeType.prototype.onAdded = function(callback) {
  var added, data;
  if (!_.isFunction(callback)) {
    throw new TypeError('expected callback function for onNodeAdded call');
  }
  added = (data = this[bData]).added;
  if (!added) {
    data.added = added = [];
    Lill.attach(added);
  }
  added.push(callback);
  return this;
};

NodeType.prototype.onRemoved = function(callback) {
  var data, removed;
  if (!_.isFunction(callback)) {
    throw new TypeError('expected callback function for onNodeRemoved call');
  }
  removed = (data = this[bData]).removed;
  if (!removed) {
    data.removed = removed = [];
    Lill.attach(removed);
  }
  removed.push(callback);
  return this;
};

NodeType.prototype.finish = function() {
  var added, addedCb, data, removed, removedCb, _i, _j, _len, _len1;
  data = this[bData];
  if ((added = data.added) && Lill.getSize(added)) {
    for (_i = 0, _len = added.length; _i < _len; _i++) {
      addedCb = added[_i];
      Lill.each(added, addedCb);
    }
    Lill.clear(added);
  }
  if ((removed = data.removed) && Lill.getSize(removed)) {
    for (_j = 0, _len1 = removed.length; _j < _len1; _j++) {
      removedCb = removed[_j];
      Lill.each(removed, removedCb);
    }
    Lill.each(removed, data.pool);
    Lill.clear(removed);
  }
  return this;
};

Object.defineProperties(NodeType.prototype, {
  'head': {
    enumerable: true,
    get: function() {
      return Lill.getHead(this);
    }
  },
  'tail': {
    enumerable: true,
    get: function() {
      return Lill.getTail(this);
    }
  },
  'size': {
    enumerable: true,
    get: function() {
      return Lill.getSize(this);
    }
  }
});

createNodeItem = function(nodeType, componentTypes) {
  var NodeItem, componentType, _i, _len;
  NodeItem = function() {};
  NodeItem.prototype = new BaseNodeItem(nodeType);
  for (_i = 0, _len = componentTypes.length; _i < _len; _i++) {
    componentType = componentTypes[_i];
    defineComponentProperty(NodeItem, componentType);
  }
  return NodeItem;
};

defineComponentProperty = function(nodeItemConstructor, componentType) {
  return Object.defineProperty(nodeItemConstructor.prototype, componentType.typeName, {
    enumerable: true,
    get: function() {
      return this[symbols.bEntity].get(componentType, true);
    }
  });
};

BaseNodeItem = function(nodeType) {
  this[symbols.bType] = nodeType;
  return this;
};

BaseNodeItem.prototype[symbols.bType] = null;

BaseNodeItem.prototype[symbols.bEntity] = null;

Object.defineProperty(BaseNodeItem.prototype, 'entityRef', {
  enumerable: true,
  get: function() {
    return this[symbols.bEntity];
  }
});

BaseNodeItem.prototype.inspect = function() {
  var componentType, result, _i, _len, _ref1, _ref2;
  result = {
    "--nodeType": this[symbols.bType].inspect(true),
    "--entity": this[symbols.bEntity].inspect()
  };
  _ref1 = this[symbols.bType][bData].list;
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    componentType = _ref1[_i];
    result[componentType.typeName] = (_ref2 = this[componentType.typeName]) != null ? _ref2.inspect() : void 0;
  }
  return result;
};

NodeType.prototype.inspect = function(metaOnly) {
  var data, result, toResult;
  data = this[bData];
  result = {
    "--nodeSpec": data.list.map(mapComponentName).join(','),
    "--listSize": this.size
  };
  if (metaOnly === true) {
    return result;
  }
  toResult = function(label, source) {
    var target;
    if (!(source && Lill.getSize(source))) {
      return;
    }
    target = result[label] = [];
    return Lill.each(source, function(item) {
      return target.push(item.inspect());
    });
  };
  toResult('all', this);
  toResult('added', data.added);
  toResult('removed', data.removed);
  return result;
};

mapComponentName = function(componentType) {
  return componentType.typeName;
};

poolNodeItem = function(pool, nodeItem) {
  if (!(nodeItem && pool.length)) {
    return pool.pop();
  }
  nodeItem[symbols.bEntity] = null;
  return pool.push(nodeItem);
};

validateEntity = function(entity) {
  if (!(entity && _.isFunction(entity.get))) {
    throw new TypeError('invalid entity for node type');
  }
  return entity;
};

validateComponentType = function(componentType) {
  if (!componentType) {
    return false;
  }
  return componentType instanceof Component;
};

NodeType.validateComponentTypes = function(types) {
  var _types;
  if (!_.isArray(types)) {
    _types = _([types]);
  } else {
    _types = _(types);
  }
  return _types.uniq().filter(validateComponentType).value();
};

module.exports = Object.freeze(NodeType);

},{"./component":3,"./symbols":8,"debug":undefined,"es6":undefined,"fast.js":undefined,"lill":undefined,"lodash":undefined}],7:[function(require,module,exports){
module.exports = Object.freeze([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701, 709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811, 821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997, 1009, 1013, 1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063, 1069, 1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129, 1151, 1153, 1163, 1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223, 1229, 1231, 1237, 1249, 1259, 1277, 1279, 1283, 1289, 1291, 1297, 1301, 1303, 1307, 1319, 1321, 1327, 1361, 1367, 1373, 1381, 1399, 1409, 1423, 1427, 1429, 1433, 1439, 1447, 1451, 1453, 1459, 1471, 1481, 1483, 1487, 1489, 1493, 1499, 1511, 1523, 1531, 1543, 1549, 1553, 1559, 1567, 1571, 1579, 1583, 1597, 1601, 1607, 1609, 1613, 1619, 1621, 1627, 1637, 1657, 1663, 1667, 1669, 1693, 1697, 1699, 1709, 1721, 1723, 1733, 1741, 1747, 1753, 1759, 1777, 1783, 1787, 1789, 1801, 1811, 1823, 1831, 1847, 1861, 1867, 1871, 1873, 1877, 1879, 1889, 1901, 1907, 1913, 1931, 1933, 1949, 1951, 1973, 1979, 1987, 1993, 1997, 1999, 2003, 2011, 2017, 2027, 2029, 2039, 2053, 2063, 2069, 2081, 2083, 2087, 2089, 2099, 2111, 2113, 2129, 2131, 2137, 2141, 2143, 2153, 2161, 2179, 2203, 2207, 2213, 2221, 2237, 2239, 2243, 2251, 2267, 2269, 2273, 2281, 2287, 2293, 2297, 2309, 2311, 2333, 2339, 2341, 2347, 2351, 2357, 2371, 2377, 2381, 2383, 2389, 2393, 2399, 2411, 2417, 2423, 2437, 2441, 2447, 2459, 2467, 2473, 2477, 2503, 2521, 2531, 2539, 2543, 2549, 2551, 2557, 2579, 2591, 2593, 2609, 2617, 2621, 2633, 2647, 2657, 2659, 2663, 2671, 2677, 2683, 2687, 2689, 2693, 2699, 2707, 2711, 2713, 2719, 2729, 2731, 2741, 2749, 2753, 2767, 2777, 2789, 2791, 2797, 2801, 2803, 2819, 2833, 2837, 2843, 2851, 2857, 2861, 2879, 2887, 2897, 2903, 2909, 2917, 2927, 2939, 2953, 2957, 2963, 2969, 2971, 2999, 3001, 3011, 3019, 3023, 3037, 3041, 3049, 3061, 3067, 3079, 3083, 3089, 3109, 3119, 3121, 3137, 3163, 3167, 3169, 3181, 3187, 3191, 3203, 3209, 3217, 3221, 3229, 3251, 3253, 3257, 3259, 3271, 3299, 3301, 3307, 3313, 3319, 3323, 3329, 3331, 3343, 3347, 3359, 3361, 3371, 3373, 3389, 3391, 3407, 3413, 3433, 3449, 3457, 3461, 3463, 3467, 3469, 3491, 3499, 3511, 3517, 3527, 3529, 3533, 3539, 3541, 3547, 3557, 3559, 3571, 3581, 3583, 3593, 3607, 3613, 3617, 3623, 3631, 3637, 3643, 3659, 3671, 3673, 3677, 3691, 3697, 3701, 3709, 3719, 3727, 3733, 3739, 3761, 3767, 3769, 3779, 3793, 3797, 3803, 3821, 3823, 3833, 3847, 3851, 3853, 3863, 3877, 3881, 3889, 3907, 3911, 3917, 3919, 3923, 3929, 3931, 3943, 3947, 3967, 3989, 4001, 4003, 4007, 4013, 4019, 4021, 4027, 4049, 4051, 4057, 4073, 4079, 4091, 4093, 4099, 4111, 4127, 4129, 4133, 4139, 4153, 4157, 4159, 4177, 4201, 4211, 4217, 4219, 4229, 4231, 4241, 4243, 4253, 4259, 4261, 4271, 4273, 4283, 4289, 4297, 4327, 4337, 4339, 4349, 4357, 4363, 4373, 4391, 4397, 4409, 4421, 4423, 4441, 4447, 4451, 4457, 4463, 4481, 4483, 4493, 4507, 4513, 4517, 4519, 4523, 4547, 4549, 4561, 4567, 4583, 4591, 4597, 4603, 4621, 4637, 4639, 4643, 4649, 4651, 4657, 4663, 4673, 4679, 4691, 4703, 4721, 4723, 4729, 4733, 4751, 4759, 4783, 4787, 4789, 4793, 4799, 4801, 4813, 4817, 4831, 4861, 4871, 4877, 4889, 4903, 4909, 4919, 4931, 4933, 4937, 4943, 4951, 4957, 4967, 4969, 4973, 4987, 4993, 4999, 5003, 5009, 5011, 5021, 5023, 5039, 5051, 5059, 5077, 5081, 5087, 5099, 5101, 5107, 5113, 5119, 5147, 5153, 5167, 5171, 5179, 5189, 5197, 5209, 5227, 5231, 5233, 5237, 5261, 5273, 5279, 5281, 5297, 5303, 5309, 5323, 5333, 5347, 5351, 5381, 5387, 5393, 5399, 5407, 5413, 5417, 5419, 5431, 5437, 5441, 5443, 5449, 5471, 5477, 5479, 5483, 5501, 5503, 5507, 5519, 5521, 5527, 5531, 5557, 5563, 5569, 5573, 5581, 5591, 5623, 5639, 5641, 5647, 5651, 5653, 5657, 5659, 5669, 5683, 5689, 5693, 5701, 5711, 5717, 5737, 5741, 5743, 5749, 5779, 5783, 5791, 5801, 5807, 5813, 5821, 5827, 5839, 5843, 5849, 5851, 5857, 5861, 5867, 5869, 5879, 5881, 5897, 5903, 5923, 5927, 5939, 5953, 5981, 5987, 6007, 6011, 6029, 6037, 6043, 6047, 6053, 6067, 6073, 6079, 6089, 6091, 6101, 6113, 6121, 6131, 6133, 6143, 6151, 6163, 6173, 6197, 6199, 6203, 6211, 6217, 6221, 6229, 6247, 6257, 6263, 6269, 6271, 6277, 6287, 6299, 6301, 6311, 6317, 6323, 6329, 6337, 6343, 6353, 6359, 6361, 6367, 6373, 6379, 6389, 6397, 6421, 6427, 6449, 6451, 6469, 6473, 6481, 6491, 6521, 6529, 6547, 6551, 6553, 6563, 6569, 6571, 6577, 6581, 6599, 6607, 6619, 6637, 6653, 6659, 6661, 6673, 6679, 6689, 6691, 6701, 6703, 6709, 6719, 6733, 6737, 6761, 6763, 6779, 6781, 6791, 6793, 6803, 6823, 6827, 6829, 6833, 6841, 6857, 6863, 6869, 6871, 6883, 6899, 6907, 6911, 6917, 6947, 6949, 6959, 6961, 6967, 6971, 6977, 6983, 6991, 6997, 7001, 7013, 7019, 7027, 7039, 7043, 7057, 7069, 7079, 7103, 7109, 7121, 7127, 7129, 7151, 7159, 7177, 7187, 7193, 7207, 7211, 7213, 7219, 7229, 7237, 7243, 7247, 7253, 7283, 7297, 7307, 7309, 7321, 7331, 7333, 7349, 7351, 7369, 7393, 7411, 7417, 7433, 7451, 7457, 7459, 7477, 7481, 7487, 7489, 7499, 7507, 7517, 7523, 7529, 7537, 7541, 7547, 7549, 7559, 7561, 7573, 7577, 7583, 7589, 7591, 7603, 7607, 7621, 7639, 7643, 7649, 7669, 7673, 7681, 7687, 7691, 7699, 7703, 7717, 7723, 7727, 7741, 7753, 7757, 7759, 7789, 7793, 7817, 7823, 7829, 7841, 7853, 7867, 7873, 7877, 7879, 7883, 7901, 7907, 7919]);

},{}],8:[function(require,module,exports){
'use strict';
var Symbol;

Symbol = require('es6').Symbol;

exports.bName = Symbol('name of the object');

exports.bType = Symbol('type of the object');

exports.bDispose = Symbol('method to dispose object');

exports.bRelease = Symbol('method to release disposed object');

exports.bChanged = Symbol('timestamp of last change');

exports.bDisposing = Symbol('timestamp of the object disposal');

exports.bEntity = Symbol('reference to entity instance');

exports.Symbol = Symbol;

exports.bIdentity = Symbol('identifier of the object');

exports.bFields = Symbol('fields defined for the component');

exports.bDefinition = Symbol('definition of the component');

},{"es6":undefined}],9:[function(require,module,exports){
var symbols, _;

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

},{"./symbols":8,"lodash":undefined}]},{},[1])(1)
});