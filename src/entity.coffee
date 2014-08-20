'use strict'

log = (require 'debug') 'scent:entity'
_ = require 'lodash'
lill = require 'lill'
NoMe = require 'nome'

{Symbol, Map} = require './es6-support'

symbols = require './symbols'
bEntity = Symbol 'represent entity reference on the component'
bList = Symbol 'map of components in the entity'
bEntityChanged = Symbol 'timestamp of change of component list'

entityPool = lill.attach {}

Entity = (components) ->

	if components and not _.isArray components
		throw new TypeError 'expected array of components for entity'

	if entity = lill.getTail entityPool
		lill.remove entityPool, entity
	else
		entity = Object.create entityPrototype, entityProps
		entity[ bList ] = new Map
		entity[ symbols.bDispose ] = Entity.disposed
		entity[ symbols.bNodes ] = new Map

	# Add components passed in constructor
	components?.forEach entity.add, entity

	return entity

entityProps = 'size': get: -> return this[ bList ].size

entityPrototype =
	add: (component) ->
		validateComponent component
		return this if hasOtherEntity component, this
		if this[ bList ].has componentType = component[ symbols.bType ]
			log 'entity already contains component `%s`, consider using replace method if this is intended', component[ symbols.bName ]
		Entity.componentAdded.call this, component
		return this

	replace: (component) ->
		validateComponent component
		return this if hasOtherEntity component, this
		if currentComponent = this[ bList ].get component[ symbols.bType ]
			delete currentComponent[ bEntity ]
		Entity.componentAdded.call this, component
		return this

	has: (componentType) ->
		validateComponentType componentType
		return this[ bList ].has componentType

	get: (componentType) ->
		validateComponentType componentType
		return this[ bList ].get(componentType) or null

	remove: (componentType, dispose) ->
		validateComponentType componentType
		if false isnt dispose and component = this[ bList ].get componentType
			disposeComponent component
		Entity.componentRemoved.call this, componentType

Object.defineProperty entityPrototype, symbols.bChanged, get: ->
	return 0 unless changed = this[ bEntityChanged ]
	components = this[ bList ].values()
	entry = components.next()
	while not entry.done
		changed = Math.max changed, entry.value[ symbols.bChanged ]
		entry = components.next()
	return changed

Entity.componentAdded = NoMe (component) ->
	component[ bEntity ] = this
	this[ bList ].set component[ symbols.bType ], component
	this[ bEntityChanged ] = Date.now()
	return this

Entity.componentRemoved = NoMe (componentType) ->
	delete this[ bList ].get(componentType)?[ bEntity ]
	if this[ bList ].delete componentType
		this[ bEntityChanged ] = Date.now()
	return this

Entity.disposed = NoMe ->
	this[ bList ].forEach disposeComponent
	this[ bList ].clear()
	delete this[ bEntityChanged ]
	lill.add entityPool, this
	return this

(require './component').disposed[ NoMe.bNotify ] ->
	if entity = this[ bEntity ]
		entity.remove this[ symbols.bType ]
		delete this[ bEntity ]

hasOtherEntity = (component, entity) ->
	if result = inEntity = component[ bEntity ] and inEntity isnt entity
		log 'component %s cannot be shared with multiple entities', component
	return result

disposeComponent = (component) ->
	delete component[ bEntity ]
	do component[ symbols.bDispose ]

validateComponent = (component) ->
	unless component
		throw new TypeError 'missing component for entity'
	validateComponentType component[ symbols.bType ]

validateComponentType = (componentType) ->
	unless _.isFunction(componentType) and componentType[ symbols.bIdentity ]
		throw new TypeError 'invalid component type for entity'

Object.freeze Entity
module.exports = Entity
