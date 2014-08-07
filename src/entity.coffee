log = (require 'debug') 'scent:entity'
_ = require 'lodash'

require 'es6-shim'
entities = new Map

symbols = require './symbols'
{Symbol, sDispose, sType, sNodes} = symbols
sList = Symbol 'list of components in the entity'

module.exports = (id) ->

	if hasId = (arguments.length > 0)
		unless _.isString(id) or _.isNumber(id) 
			throw new TypeError 'invalid id for entity, expected string or number'

	# Return existing entity
	return entity if hasId and entity = entities.get id

	# Fetch entity from the pool or create fresh one
	if entityPool.length
		entity = entityPool.pop()
	else
		entity = Object.create Entity
		entity[ sList ] = new Map
		entity[ sDispose ] = dispose
		entity[ sNodes ] = new Map

	# Handle entity with ID
	if hasId	
		Object.defineProperty entity, 'id', {enumerable: yes, get: -> id}
		entities.set id, entity

	Object.freeze entity
	return entity

entityPool = []

Entity =
	add: (component) ->
		validateComponent component
		if this[sList].has componentType = component[sType]
			log 'entity %s already contains component `%s`, consider using replace method if this is intended', this, component[symbols.sName]
		this[sList].set componentType, component
		return this

	replace: (component) ->
		validateComponent component
		this[sList].set component[sType], component
		return this

	has: (componentType) ->
		validateComponentType componentType
		return this[sList].has componentType

	get: (componentType) ->
		validateComponentType componentType
		return this[sList].get(componentType) or null

	remove: (componentType, dispose) ->
		validateComponentType componentType
		if false isnt dispose and component = this[sList].get componentType
			disposeComponent component
		return this[sList].delete(componentType)

dispose = ->
	this[sList].forEach disposeComponent
	this[sList].clear()
	if this.id
		entities.delete this.id
		this.id = undefined
	else
		entityPool.push this

disposeComponent = (component) ->
	do component[sDispose]

validateComponent = (component) ->
	unless component
		throw new TypeError 'missing component for entity'
	validateComponentType component[sType]

validateComponentType = (componentType) ->
	unless _.isFunction(componentType) and componentType[symbols.sNumber]
		throw new TypeError 'invalid component for entity'
	