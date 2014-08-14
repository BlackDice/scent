'use strict'

log = (require 'debug') 'scent:engine'
_ = require 'lodash'
fast = require 'fast.js'
fnArgs = require 'fn-args'
async = require 'async'

{Map} = require './es6-support'

symbols = require './symbols'

Node = require './node'
Entity = require './entity'

Engine = (initializer) ->

    if initializer? and not _.isFunction initializer
        throw new TypeError 'expected function as engine initializer'

    engine = Object.create null

    isStarted = no
    memoryMap = new Map 
    systemList = []
    injections = new Map

    engine.getNode = (componentTypes) -> 
        return Node componentTypes, memoryMap

    engine.addEntity = (components) ->
        return Entity components

    engine.addSystem = (systemInitializer) ->
        unless systemInitializer and _.isFunction systemInitializer
            throw new TypeError 'expected function for addSystem call'

        if ~fast.indexOf systemList, systemInitializer
            throw new Error 'system is already added to engine'

        unless name = systemInitializer[ symbols.bName ]
            throw new TypeError 'function for addSystem is not system initializer'

        fast.forEach systemList, (storedSystem) ->
            if storedSystem[ symbols.bName ] is name
                throw new TypeError 'name for system has to be unique'

        systemList.push systemInitializer
        if isStarted
            initializeSystem systemInitializer

        return engine

    engine.addSystems = (list) ->
        unless list and _.isArray list
            throw new TypeError 'expected array of system initializers'

        engine.addSystem systemInitializer for systemInitializer in list
        return engine

    engine.start = (done) ->
        if done? and not _.isFunction done
            throw new TypeError 'expected callback function for engine start'

        if isStarted
            throw new Error 'engine has been started already'
        
        if done
            async.each systemList, initializeSystemAsync, (err) ->
                isStarted = yes
                done err
        else
            fast.forEach systemList, initializeSystem
            isStarted = yes

        return this

    initializeSystemAsync = (systemInitializer, cb) ->
        handleError = (fn) ->
            result = fast.try fn
            return cb if result instanceof Error then result else null

        unless systemInitializer.length
            return handleError -> systemInitializer.call null

        args = getSystemArgs systemInitializer, cb

        unless ~fast.indexOf args, cb
            handleError -> fast.apply systemInitializer, null, args
        else
            fast.apply systemInitializer, null, args

    initializeSystem = (systemInitializer) ->
        handleError = (fn) ->
            result = fast.try fn
            throw result if result instanceof Error

        unless systemInitializer.length
            return handleError -> systemInitializer.call null

        args = getSystemArgs systemInitializer
        handleError -> fast.apply systemInitializer, null, args

    getSystemArgs = (systemInitializer, done) ->
        args = fnArgs systemInitializer
        fast.forEach args, (argName, i) ->
            if done and argName is 'done'
                injection = done
            else
                injection = if injections.has argName
                    injections.get(argName)
                else null

                if _.isFunction injection
                    injection = injection.call null, engine, systemInitializer

            args[i] = injection

        return args

    provide = (name, injection) ->
        if Object.isFrozen engine
            throw new Error 'cannot call provide for initialized engine'

        unless name?.constructor is String and name.length
            throw new TypeError 'expected injection name for provide call'

        if injections.has name
            throw new TypeError 'injection of that name is already defined'

        unless injection?
            throw new TypeError 'expected non-null value for injection'

        injections.set name, injection
        return

    provide 'engine', engine

    if initializer
        initializer.call null, engine, provide
        initializer = null

    return Object.freeze engine

module.exports = Object.freeze Engine

