'use strict'

log = (require 'debug') 'scent:component'
_ = require 'lodash'
fast = require 'fast.js'
NoMe = require 'nome'

{Symbol, Map, Set} = require 'es6'

symbols = require './symbols'
bPool = Symbol 'pool of disposed components'
bData = Symbol 'data array for the component'
bSetup = Symbol 'private setup method for component'

identities = fast.clone(require './primes').reverse()

fieldsRx = /(?:^|\s)([a-z][a-z0-9]*(?=\s|$))/gi
identityRx = /(?:^|\s)#([0-9]+(?=\s|$))/i

Component = (name, definition) ->
	# Sanity check to avoid creating new component type if one
	# is already passed in. This allows to leave determining logic
	# in one place.
	return definition if definition instanceof Component

	unless _.isString name
		throw new TypeError 'missing name of the component'

	ComponentType = (data) ->
		component = this
		unless component instanceof ComponentType
			component = new ComponentType data
		initializeData component, ComponentType.typeFields, data
		return component

	ComponentType.prototype = new BaseComponent name, definition
	# Back reference type from component instances through prototype
	ComponentType::[ symbols.bType ] = ComponentType

	# Make the component type inherited from the Component
	Object.setPrototypeOf ComponentType, Component.prototype
	return Object.freeze ComponentType

Component.prototype = Object.create Function.prototype

poolMap = new Map

Component::pooled = ->
	unless (pool = poolMap.get this)?
		poolMap.set this, pool = []
	return pool.pop() if pool.length
	return new this

Component::toString = ->
	type = this.prototype
	"ComponentType `#{type[ symbols.bName ]}` ##{type[ symbols.bIdentity ]}" +
	unless fields = type[ symbols.bFields ] then ""
	else " [#{fields.join(' ')}]"

Object.defineProperties Component.prototype, {
	'typeName':
		enumerable: yes
		get: -> this::[ symbols.bName ]
	'typeIdentity':
		enumerable: yes
		get: -> this::[ symbols.bIdentity ]
	'typeFields':
		enumerable: yes
		get: -> this::[ symbols.bFields ]
	'typeDefinition':
		enumerable: yes
		get: ->
			# Used for serialization purposes of the component type
			return "##{this::[ symbols.bIdentity ]}" +
			unless fields = this::[ symbols.bFields ] then ""
			else " #{fields.join(' ')}"
}

# Exposed NoMe method to get notified about component disposal
Component.disposed = NoMe ->
	this[ symbols.bDisposing ] = Date.now()

###
# BaseComponent
###

BaseComponent = (name, definition) ->
	this[ symbols.bName ] = name

	this[ bSetup ] definition
	for field, i in this[ symbols.bFields ]
		defineFieldProperty this, field, i

	return this

BaseComponent::[ bSetup ] = (definition) ->
	# With missing definition, grab the identity, fields are taken
	# from the prototype as an empty array
	if typeof definition is 'undefined' or not definition?
		this[ symbols.bIdentity ] = identities.pop()
		return

	# String type check for definition if specified
	if typeof definition isnt "string"
		throw new TypeError 'optionally expected string definition for component type, got:' + definition

	# Fields are parsed using RX in the loop while throwing away duplicates
	fields = null
	while match = fieldsRx.exec definition
		fields ?= []
		fields.push field unless ~(fast.indexOf fields, field = match[1])

	if fields?
		this[ symbols.bFields ] = Object.freeze fields

	# Identity is matched using RX in format #123 or obtained
	# next available
	if identityMatch = definition.match identityRx
		identity = Number identityMatch[1]
		unless ~(idx = fast.indexOf identities, identity)
			throw new Error 'invalid identity specified for component: '+identity
		identities.splice idx, 1
	else
		identity = identities.pop()

	this[ symbols.bIdentity ] = identity
	return

BaseComponent::[ symbols.bName ] = null
BaseComponent::[ symbols.bIdentity ] = null
BaseComponent::[ symbols.bFields ] = emptyFields = Object.freeze []
BaseComponent::[ symbols.bChanged ] = 0
BaseComponent::[ symbols.bDispose ] = Component.disposed

BaseComponent::[ symbols.bRelease ] = ->
	return false unless this[ symbols.bDisposing ]
	delete this[ symbols.bDisposing ]

	if data = this[ bData ]
		data.length = 0
		delete this[ symbols.bChanged ]

	if pool = poolMap.get this[ symbols.bType ]
		pool.push this
	return true

BaseComponent::toString = ->
	"Component `#{this[ symbols.bName ]}` ##{this[ symbols.bIdentity ]}" +
	unless fields = this[ symbols.bFields ] then ""
	else " [#{fields.join(' ')}]" +
	unless changed = this[ symbols.bChanged ] then ""
	else "(changed: #{changed})"

BaseComponent::inspect = ->
	result = {
		"--typeName": this[ symbols.bName ]
		"--typeIdentity": this[ symbols.bIdentity ]
		"--changed": this[ symbols.bChanged ]
	}

	if this[ symbols.bDisposing ]
		result['--disposing'] = this[ symbols.bDisposing ]

	for field in this[ symbols.bFields ]
		result[field] = this[field]

	return result

Object.freeze BaseComponent

defineFieldProperty = (target, field, i) ->
	Object.defineProperty target, field, {
		enumerable: yes
		get: ->
			if undefined is (val = this[ bData ][i]) then null
			else val
		set: (val) ->
			this[ symbols.bChanged ] = Date.now()
			this[ bData ][i] = val
	}

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

module.exports = Object.freeze Component