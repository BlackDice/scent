'use strict'

log = (require 'debug') 'scent:engine'
_ = require 'lodash'
fast = require 'fast.js'
fnArgs = require 'fn-args'
async = require 'async'
NoMe = require 'nome'
Lill = require 'lill'

{Map} = require 'es6'

symbols = require './symbols'
Node = require './node'
Entity = require './entity'

Engine = (initializer) ->

	if initializer? and not _.isFunction initializer
		throw new TypeError 'expected function as engine initializer'

	engine = Object.create null
	isStarted = no

	# Memory map of node types used by this engine
	nodeMap = new Map

	engine.getNodeType = (componentTypes) ->
		return Node componentTypes, nodeMap

	# List of all entities in this engine
	engine.entityList = Lill.attach {}

	# List of entities that were updated
	updatedEntities = Lill.attach {}

	engine.addEntity = (components) ->
		entity = Entity components
		Lill.add engine.entityList, entity
		Lill.add updatedEntities, entity
		return entity

	systemList = []
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

	engine.update = NoMe ->
		nodeTypes = nodeMap.values()
		entry = nodeTypes.next()
		while not entry.done
			updateNodeTypes entry.value
			entry = nodeTypes.next()
		Lill.clear updatedEntities

	engine.onUpdate = fast.bind engine.update.notify, engine.update

	nomeDisposed = Entity.disposed.notify ->
		# TODO: Possible error if disposing entity that is not
		# in this engine, it would be added to it like this!
		Lill.add updatedEntities, this
		Lill.remove engine.entityList, this

	nomeAdded = Entity.componentAdded.notify ->
		Lill.add updatedEntities, this
	nomeRemoved = Entity.componentRemoved.notify ->
		Lill.add updatedEntities, this

	engine[ symbols.bDispose ] = ->
		Entity.disposed.denotify nomeDisposed
		Entity.componentAdded.denotify nomeAdded
		Entity.componentRemoved.denotify nomeRemoved
		nodeMap.clear()
		systemList.length = 0
		injections.clear()
		Lill.detach updatedEntities
		isStarted = no

	updateNodeTypes = (nodeType) ->
		Lill.each updatedEntities, (entity) ->
			nodeType.updateEntity entity

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
			if done and argName is '$done'
				injection = done
			else
				injection = if injections.has argName
					injections.get(argName)
				else null

				if _.isFunction injection
					injection = injection.call null, engine, systemInitializer

			args[i] = injection

		return args

	injections = new Map

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

	provide '$engine', engine

	if initializer
		initializer.call null, engine, provide
		initializer = null

	Object.setPrototypeOf engine, Engine.prototype
	return Object.freeze engine

Engine.prototype = Object.create Function.prototype
Engine.prototype.toString = -> "Engine (#{Lill.getSize this.entityList} entities)"

module.exports = Object.freeze Engine
