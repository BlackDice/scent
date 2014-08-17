log = (require 'debug') 'scent:component'
_ = require 'lodash'
fast = require 'fast.js'
lill = require 'lill'

{Symbol, Map} = require './es6-support'

symbols = require './symbols'
bPool = Symbol 'pool of disposed components'
bData = Symbol 'data array for the component'

components = new Map
componentIdentities = fast.clone(require './primes').reverse()

module.exports = Component = (name, opts) ->
	verifyName name

	return ComponentType if ComponentType = components.get name

	if opts and _.isPlainObject opts
		fields = opts.fields
		identity = verifyIdentity opts.identity
	else 
		fields = opts
		identity = componentIdentities.pop()

	if fields
		fields = verifyFields fields
		props = fast.reduce fields, reduceProperty, {}
	else
		fields = emptyFields

	proto = Object.create componentPrototype
 
	ComponentType = ->
		if (pool = ComponentType[ bPool ]).length
			component = pool.pop()
		else
			component = Object.create proto, props
			component[ bData ] = new Array(fields.length) if fields.length
		Object.freeze component
		return component

	proto[ symbols.bType ] = ComponentType

	ComponentType[ bPool ] = []
	ComponentType[ symbols.bFields ] = fields
	ComponentType[ symbols.bName ] = name
	ComponentType[ symbols.bIdentity ] = identity

	toString = "Component #{name}: " + fields.join ', '
	ComponentType.toString = -> toString    
	
	Object.freeze ComponentType
	components.set name, ComponentType
	return ComponentType

componentPrototype = {}
componentPrototype[ symbols.bDispose ] = dispose = ->
	return unless data = this[ bData ]
	data.length = 0
	this[ symbols.bType ][ bPool ].push this
Object.freeze componentPrototype

emptyFields = Object.freeze []

reduceField = (fields, field) ->
	return fields unless _.isString(field)
	fields.push field
	return fields

reduceProperty = (props, field, i) ->
	props[field] =
		enumerable: yes
		get: -> return this[ bData ][i]
		set: (val) -> this[ bData ][i] = val
	return props

verifyName = (name) ->
	unless _.isString name 
		throw new TypeError 'missing name of the component'

verifyFields = (fields) ->
	unless _.isArray(fields) and (result = fast.reduce _.uniq(fields), reduceField, []).length
		throw new TypeError 'invalid fields specified for component: '+fields
	return result

verifyIdentity = (identity) ->
	identity = Number(identity)
	unless ~fast.indexOf componentIdentities, identity
		throw new Error 'invalid identity used for component: '+identity
	return identity
