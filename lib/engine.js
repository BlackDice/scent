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
  var actionHandlerMap, actionMap, engine, getSystemArgs, initializeSystem, initializeSystemAsync, injections, isStarted, nodeMap, nomeAdded, nomeDisposed, nomeRemoved, provide, systemList, updateNodeTypes, updatedEntities;
  if ((initializer != null) && !_.isFunction(initializer)) {
    throw new TypeError('expected function as engine initializer');
  }
  engine = Object.create(null);
  isStarted = false;
  nodeMap = new Map;
  engine.getNodeType = function(componentTypes) {
    return Node(componentTypes, nodeMap);
  };
  actionMap = new Map;
  actionHandlerMap = new Map;
  engine.getActionType = function(actionName, noCreate) {
    var actionType;
    if (!(actionType = actionMap.get(actionName))) {
      if (noCreate === true) {
        return null;
      }
      actionType = new Action(actionName);
      actionMap.set(actionName, actionType);
    }
    return actionType;
  };
  engine.triggerAction = function(actionName) {
    var actionType, arg, args, i;
    actionType = engine.getActionType(actionName);
    if (!actionHandlerMap.has(actionType)) {
      log("Action `%s` cannot be triggered. Use onAction method to add handler first.", actionName);
      return engine;
    }
    if (arguments.length > 0) {
      args = (function() {
        var _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = arguments.length; _i < _len; i = ++_i) {
          arg = arguments[i];
          if (i > 0) {
            _results.push(arg);
          }
        }
        return _results;
      }).apply(this, arguments);
      fast.apply(actionType.trigger, actionType, args);
    } else {
      actionType.trigger();
    }
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
  engine.entityList = Lill.attach({});
  updatedEntities = Lill.attach({});
  engine.addEntity = function(components) {
    var entity;
    entity = Entity(components);
    Lill.add(engine.entityList, entity);
    Lill.add(updatedEntities, entity);
    return entity;
  };
  Object.defineProperty(engine, 'size', {
    get: function() {
      return Lill.getSize(engine.entityList);
    }
  });
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
    var actionType, actionTypeEntry, actionTypes, callback, callbacks, entry, nodeTypes, _i, _len;
    actionTypes = actionHandlerMap.keys();
    actionTypeEntry = actionTypes.next();
    while (!actionTypeEntry.done) {
      actionType = actionTypeEntry.value;
      callbacks = actionHandlerMap.get(actionType);
      for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
        callback = callbacks[_i];
        actionType.each(callback);
      }
      actionType.finish();
      actionTypeEntry = actionTypes.next();
    }
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
