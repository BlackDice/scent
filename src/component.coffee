'use strict'

log = (require 'debug') 'scent:component'
_ = require 'lodash'
fast = require 'fast.js'
NoMe = require 'nome'

{Symbol, Map, Set} = require 'es6'

symbols = require './symbols'
bPool = Symbol 'pool of disposed components'
bData = Symbol 'data array for the component'

identities = fast.clone(require './primes').reverse()

fieldsRx = /(?:^|\s)([a-z][a-z0-9]*(?=\s|$))/gi
identityRx = /(?:^|\s)#([0-9]+(?=\s|$))/i

Component = (name, definition) ->
	verifyName name

	return definition if definition instanceof Component

	{fields, identity} = parseDefinition definition

	componentPool = []

	# Create prototype object for instances of the component type
	componentPrototype = Object.create basePrototype
	for field, i in fields
		Object.defineProperty componentPrototype, field, createDataProperty(i)

	ComponentType = (data) ->
		if not data and componentPool.length
			component = componentPool.pop()
		else
			component = Object.create componentPrototype
			initializeData component, fields, data
			Object.setPrototypeOf component, ComponentType.prototype
		return component

	ComponentType[ bPool ] = componentPool
	ComponentType[ symbols.bFields ] = fields
	ComponentType[ symbols.bName ] = name
	ComponentType[ symbols.bIdentity ] = identity

	toString = "Component #{name}: " + fields.join ', '
	ComponentType.toString = -> toString

	componentPrototype[ symbols.bType ] = ComponentType
	componentPrototype[ symbols.bChanged ] = 0

	ComponentType.prototype = componentPrototype
	Object.setPrototypeOf ComponentType, Component.prototype
	return Object.freeze ComponentType

Component.prototype = Object.create Function.prototype

verifyName = (name) ->
	unless _.isString name
		throw new TypeError 'missing name of the component'

emptyFields = Object.freeze []

parseDefinition = (definition) ->
	unless definition?
		return fields: emptyFields, identity: identities.pop()

	if definition? and not _.isString definition
		throw new TypeError 'optionally expected string in second argument'

	fields = []

	while match = fieldsRx.exec definition
		fields.push field unless ~(fast.indexOf fields, field = match[1])

	Object.freeze fields

	if identityMatch = definition.match identityRx
		identity = Number identityMatch[1]
		unless ~(idx = fast.indexOf identities, identity)
			throw new Error 'invalid identity specified for component: '+identity
		identities.splice idx, 1
	else
		identity = identities.pop()

	return {fields, identity}

Component.disposed = NoMe ->
	return unless data = this[ bData ]
	data.length = 0
	delete this[ symbols.bChanged ]
	this[ symbols.bType ][ bPool ].push this

basePrototype =
	toString: -> this[ symbols.bType ].toString() + if data = this[ bData ]
		JSON.stringify(data)
	else ""

basePrototype[ symbols.bDispose ] = Component.disposed

createDataProperty = (i) ->
	enumerable: yes
	get: -> unless undefined is (val = this[ bData ][i]) then val else null
	set: (val) ->
		this[ symbols.bChanged ] = Date.now()
		this[ bData ][i] = val

initializeData = (component, fields, data) ->
	return unless fields.length
	if data and _.isArray data
		data.length = fields.length
		component[ bData ] = data
	else
		component[ bData ] = new Array(fields.length)
	return

if typeof IN_TEST isnt 'undefined'
	Component.identities = identities

Object.freeze basePrototype
module.exports = Object.freeze Component