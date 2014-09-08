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
* Version: 0.1.0
*/
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
  engine.onUpdate = engine.update.notify;
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
      if (done && argName === 'done') {
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
  provide('engine', engine);
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
