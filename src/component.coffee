log = (require 'debug') 'scent:component'
_ = require 'lodash'
fast = require 'fast.js'
lill = require 'lill'
NoMe = require 'nome'

{Symbol, Map} = require './es6-support'

symbols = require './symbols'
bPool = Symbol 'pool of disposed components'
bData = Symbol 'data array for the component'

components = new Map
componentIdentities = fast.clone(require './primes').reverse()

Component = (name, opts) ->
	verifyName name

	return ComponentType if ComponentType = components.get name

	# Extract fields and identity from options object
	if opts and _.isPlainObject opts
		fields = verifyFields opts.fields
		identity = verifyIdentity opts.identity

	# Otherwise treat argument as fields and grab next available identity
	else
		fields = verifyFields opts
		identity = componentIdentities.pop()

	componentPool = []

	# Create prototype object for instances of the component type
	componentPrototype = Object.create basePrototype
	for field, i in fields
		Object.defineProperty componentPrototype, field, createDataProperty(i)

	ComponentType = ->
		if componentPool.length
			component = componentPool.pop()
		else
			component = Object.create componentPrototype
			initializeData component, fields
		return component

	ComponentType[ bPool ] = componentPool
	ComponentType[ symbols.bFields ] = fields
	ComponentType[ symbols.bName ] = name
	ComponentType[ symbols.bIdentity ] = identity

	toString = "Component #{name}: " + fields.join ', '
	ComponentType.toString = -> toString

	componentPrototype[ symbols.bType ] = ComponentType
	componentPrototype[ symbols.bChanged ] = 0

	components.set name, ComponentType
	return Object.freeze ComponentType

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

initializeData = (component, fields) ->
	return unless fields.length
	component[ bData ] = new Array(fields.length)

verifyName = (name) ->
	unless _.isString name
		throw new TypeError 'missing name of the component'

emptyFields = Object.freeze new Array(0)

reduceField = (fields, field) ->
	return fields unless _.isString(field)
	fields.push field
	return fields

verifyFields = (fields) ->
	return emptyFields unless fields
	unless _.isArray(fields) and (result = fast.reduce _.uniq(fields), reduceField, []).length
		throw new TypeError 'invalid fields specified for component: '+fields
	return result

verifyIdentity = (identity) ->
	identity = Number(identity)
	unless ~(idx = fast.indexOf componentIdentities, identity)
		throw new Error 'invalid identity used for component: '+identity
	componentIdentities.splice idx, 1
	return identity

if process.env.NODE_ENV is 'test'
	Component.map = components
	Component.identities = componentIdentities

Object.freeze basePrototype
module.exports = Object.freeze Component