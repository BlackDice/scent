'use strict'

log = (require 'debug') 'scent:entity'
_ = require 'lodash'

{Symbol, Map} = require './es6-support'

symbols = require './symbols'
{bDispose, bType, bNodes} = symbols
bList = Symbol 'map of components in the entity'

entityPool = {}
Lill = require 'lill'
Lill.attach entityPool

Entity = (components) ->

	if components and not _.isArray components
		throw new TypeError 'expected array of components for entity'

	if entity = Lill.getTail entityPool
		Lill.remove entityPool, entity
	else
		entity = Object.create entityPrototype, entityProps
		entity[ bList ] = new Map
		entity[ bDispose ] = Entity.disposed

	# Add components passed in constructor
	components and components.forEach entity.add, entity

	return entity

entityProps = 'size': get: -> return this[ bList ].size

entityPrototype =
	add: (component) ->
		validateComponent component
		if this[ bList ].has componentType = component[ bType ]
			log 'entity already contains component `%s`, consider using replace method if this is intended', component[ symbols.bName ]
		Entity.componentAdded.call this, component
		return this

	replace: (component) ->
		validateComponent component
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

NoMe = require 'nome'

Entity.componentAdded = NoMe (component) ->
	this[ bList ].set component[ bType ], component
	return this

Entity.componentRemoved = NoMe (componentType) ->
	this[ bList ].delete componentType
	return this

Entity.disposed = NoMe ->
	this[ bList ].forEach disposeComponent
	this[ bList ].clear()
	Lill.add entityPool, this
	return this

disposeComponent = (component) ->
	do component[ bDispose ]

validateComponent = (component) ->
	unless component
		throw new TypeError 'missing component for entity'
	validateComponentType component[ bType ]

validateComponentType = (componentType) ->
	unless _.isFunction(componentType) and componentType[ symbols.bNumber ]
		throw new TypeError 'invalid component for entity'

Object.freeze Entity
Object.freeze entityPrototype
module.exports = Entity
