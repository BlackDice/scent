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
Action = require './action'

bInitialized = symbols.Symbol("engine is initialized")

Engine = (initializer) ->

	unless this instanceof Engine
		return new Engine(initializer)

	if initializer? and not _.isFunction initializer
		throw new TypeError 'expected function as engine initializer'

	engine = this
	isStarted = no

	## ENTITIES

	engine.entityList = Lill.attach {}

	# Only method to add entity to engine
	engine.addEntity = (components) ->
		entity = Entity components
		Lill.add engine.entityList, entity
		addedEntities.push entity
		return entity

	Object.defineProperty engine, 'size', get: ->
		Lill.getSize engine.entityList

	## SYSTEMS

	systemList = []
	systemAnonCounter = 1
	engine.addSystem = (systemInitializer) ->
		unless systemInitializer and _.isFunction systemInitializer
			throw new TypeError 'expected function for addSystem call'

		if ~fast.indexOf systemList, systemInitializer
			throw new Error 'system is already added to engine'

		name = systemInitializer[ symbols.bName ]
		unless name
			name = systemInitializer.name or
			systemInitializer.displayName or
			'system' + (systemAnonCounter++)
			systemInitializer[ symbols.bName ] = name

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
		processActions()
		processNodeTypes()

	engine.onUpdate = fast.bind engine.update.notify, engine.update

	## NODES

	# Memory map of node types used by this engine
	nodeMap = {}

	# List of node types to make update loop faster
	nodeTypes = Lill.attach {}

	# Method to obtain node type object. It expects at least one component
	# type or array of multiple ones.
	engine.getNodeType = (componentTypes) ->

		validTypes = Node.validateComponentTypes componentTypes

		unless validTypes?.length
			throw new TypeError 'specify at least one component type to getNodeType'

		# calculate hash of component types
		hash = fast.reduce validTypes, hashComponent, 1

		# return existing node type from the map
		return nodeType if nodeType = nodeMap[hash]

		nodeType = new Node componentTypes
		nodeMap[hash] = nodeType
		Lill.add nodeTypes, nodeType

		Lill.each engine.entityList, (entity) ->
			nodeType.addEntity entity

		return nodeType

	hashComponent = (result, componentType) ->
		result *= componentType.typeIdentity

	addedEntities = []
	updatedEntities = []
	disposedEntities = []

	processNodeTypes = ->
		updateNodeType Node::addEntity, addedEntities
		updateNodeType Node::removeEntity, disposedEntities
		updateNodeType Node::updateEntity, updatedEntities
		Lill.each nodeTypes, finishNodeType

		# something has been modified during node type post processing
		# run recursive call to manage this
		if addedEntities.length or disposedEntities.length or updatedEntities.length
			return processNodeTypes()

		entity.release() for entity in releasedEntities
		releasedEntities.length = 0
		return

	releasedEntities = []

	finishNodeType = (nodeType) ->
		nodeType.finish()

	updateNodeType = (nodeMethod, entities) ->
		return unless entities.length
		execMethod = (nodeType) ->
			nodeMethod.call nodeType, this
		for entity in entities
			Lill.each nodeTypes, execMethod, entity
			releasedEntities.push entity
		entities.length = 0
		return

	nomeEntityDisposed = Entity.disposed.notify ->
		return unless Lill.has engine.entityList, this

		if ~(idx = addedEntities.indexOf this)
			addedEntities.splice idx, 1

		if ~(idx = updatedEntities.indexOf this)
			updatedEntities.splice idx, 1

		disposedEntities.push this
		Lill.remove engine.entityList, this

	nomeComponentAdded = Entity.componentAdded.notify ->
		return unless Lill.has engine.entityList, this

		unless ~(addedEntities.indexOf this) or ~(updatedEntities.indexOf this)
			updatedEntities.push this

	nomeComponentRemoved = Entity.componentRemoved.notify ->
		return unless Lill.has engine.entityList, this

		unless ~(addedEntities.indexOf this) or ~(updatedEntities.indexOf this)
			updatedEntities.push this

	## ACTIONS

	actionMap = new Map
	actionHandlerMap = new Map
	actionTypes = Lill.attach {}

	engine.getActionType = (actionName, noCreate) ->
		unless actionType = actionMap.get actionName
			return null if noCreate is yes
			actionType = new Action actionName
			actionMap.set actionName, actionType
			Lill.add actionTypes, actionType
		return actionType

	engine.triggerAction = (actionName, data, meta) ->
		actionType = engine.getActionType actionName
		unless actionHandlerMap.has actionType
			log "Action `%s` cannot be triggered. Use onAction method to add handler first.", actionName
			return engine

		actionType.trigger(data, meta)
		return engine

	engine.onAction = (actionName, callback) ->
		unless _.isString actionName
			throw new TypeError 'expected name of action for onAction call'
		unless _.isFunction callback
			throw new TypeError 'expected callback function for onAction call'

		actionType = engine.getActionType actionName
		unless map = actionHandlerMap.get actionType
			map = [callback]
			actionHandlerMap.set actionType, map
		else
			map.push callback
		return engine

	processActions = ->
		Lill.each actionTypes, processActionType

	processActionType = (actionType) ->
		callbacks = actionHandlerMap.get actionType
		return unless callbacks and callbacks.length
		for callback in callbacks
			actionType.each callback
		actionType.finish()

	engine[ symbols.bDispose ] = ->
		Entity.disposed.denotify nomeEntityDisposed
		Entity.componentAdded.denotify nomeComponentAdded
		Entity.componentRemoved.denotify nomeComponentRemoved
		nodeTypes.length = 0
		systemList.length = 0
		injections.clear()
		Lill.detach actionTypes
		actionMap.clear()
		actionHandlerMap.clear()
		addedEntities.length = 0
		updatedEntities.length = 0
		disposedEntities.length = 0
		isStarted = no

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
		if engine[bInitialized]
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
		initializer engine, provide
		initializer = null

	engine[bInitialized] = true
	return engine

Engine.prototype = Object.create Function.prototype
Engine.prototype.toString = -> "Engine (#{Lill.getSize this.entityList} entities)"

module.exports = Object.freeze Engine
