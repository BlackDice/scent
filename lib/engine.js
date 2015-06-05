'use strict';
var Action, Engine, Entity, Lill, Map, NoMe, Node, Set, _, async, bInitialized, fast, fnArgs, log, ref, symbols;

log = (require('debug'))('scent:engine');

_ = require('lodash');

fast = require('fast.js');

fnArgs = require('fn-args');

async = require('async');

NoMe = require('nome');

Lill = require('lill');

ref = require('es6'), Map = ref.Map, Set = ref.Set;

symbols = require('./symbols');

Node = require('./node');

Entity = require('./entity');

Action = require('./action');

bInitialized = symbols.Symbol("engine is initialized");

Engine = function(initializer) {
  var actionHandlerMap, actionMap, actionTypes, actionTypesProcessed, actionsTriggered, addedEntities, disposedEntities, engine, finishNodeType, getSystemArgs, hashComponent, initializeSystem, initializeSystemAsync, injections, isStarted, nodeMap, nodeTypes, nomeComponentAdded, nomeComponentRemoved, nomeEntityDisposed, processActionType, processActions, processNodeTypes, provide, releasedEntities, systemAnonCounter, systemList, updateNodeType, updatedEntities;
  if (!(this instanceof Engine)) {
    return new Engine(initializer);
  }
  if ((initializer != null) && !_.isFunction(initializer)) {
    throw new TypeError('expected function as engine initializer');
  }
  engine = this;
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
    var j, len, systemInitializer;
    if (!(list && _.isArray(list))) {
      throw new TypeError('expected array of system initializers');
    }
    for (j = 0, len = list.length; j < len; j++) {
      systemInitializer = list[j];
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
    Lill.each(engine.entityList, function(entity) {
      return nodeType.addEntity(entity);
    });
    return nodeType;
  };
  hashComponent = function(result, componentType) {
    return result *= componentType.typeIdentity;
  };
  addedEntities = [];
  updatedEntities = [];
  disposedEntities = [];
  processNodeTypes = function() {
    var entity, j, len;
    updateNodeType(Node.prototype.addEntity, addedEntities);
    updateNodeType(Node.prototype.removeEntity, disposedEntities);
    updateNodeType(Node.prototype.updateEntity, updatedEntities);
    Lill.each(nodeTypes, finishNodeType);
    if (addedEntities.length || disposedEntities.length || updatedEntities.length) {
      return processNodeTypes();
    }
    for (j = 0, len = releasedEntities.length; j < len; j++) {
      entity = releasedEntities[j];
      entity.release();
    }
    releasedEntities.length = 0;
  };
  releasedEntities = [];
  finishNodeType = function(nodeType) {
    return nodeType.finish();
  };
  updateNodeType = function(nodeMethod, entities) {
    var entity, execMethod, j, len;
    if (!entities.length) {
      return;
    }
    execMethod = function(nodeType) {
      return nodeMethod.call(nodeType, this);
    };
    for (j = 0, len = entities.length; j < len; j++) {
      entity = entities[j];
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
  actionsTriggered = 0;
  actionTypesProcessed = new Set;
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
    actionsTriggered += 1;
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
    Lill.each(actionTypes, processActionType);
    if (actionsTriggered !== 0) {
      actionsTriggered = 0;
      return processActions();
    }
    return actionTypesProcessed.clear();
  };
  processActionType = function(actionType) {
    var callback, callbacks, j, len;
    if (actionType.size === 0) {
      return;
    }
    if (actionTypesProcessed.has(actionType)) {
      log("Detected recursive action triggering. Action `%s` has been already processed during this update.", actionType[symbols.bName]);
      actionsTriggered -= actionType.size;
      return;
    }
    callbacks = actionHandlerMap.get(actionType);
    if (!(callbacks && callbacks.length)) {
      return;
    }
    for (j = 0, len = callbacks.length; j < len; j++) {
      callback = callbacks[j];
      actionType.each(callback);
    }
    actionType.finish();
    return actionTypesProcessed.add(actionType);
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
    if (engine[bInitialized]) {
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
    initializer(engine, provide);
    initializer = null;
  }
  engine[bInitialized] = true;
  return engine;
};

Engine.prototype = Object.create(Function.prototype);

Engine.prototype.toString = function() {
  return "Engine (" + (Lill.getSize(this.entityList)) + " entities)";
};

module.exports = Object.freeze(Engine);
