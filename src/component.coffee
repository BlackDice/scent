log = (require 'debug') 'scent:component'
_ = require 'lodash'
fast = require 'fast.js'

require 'es6-shim'
components = new Map

symbols = require './symbols'
{Symbol, sType} = symbols
sPool = Symbol 'pool of disposed components'
sData = Symbol 'data array for the component'

emptyFields = []

componentNumbers = require './component-number'

module.exports = Component = (name, fields) ->
	unless _.isString name 
		throw new TypeError 'missing name of the component'

	# Return existing factory by the name
	return Factory if Factory = components.get name

	if fields and not (_.isArray(fields) and (fields = fast.reduce fields, reduceField, []).length)
		throw new TypeError 'invalid fields specified for component: '+fields
	
	fields or= emptyFields

	# log 'component with fields %j has been defined before', fields

	# Create properties based on the fields
	props = Object.create(null)
	props[sData] = writable: yes

	fast.reduce fields, createProps, props if fields isnt emptyFields

	proto = {}
	proto[symbols.sDispose] = dispose

	Factory = ->
		return pool.pop() if (pool = Factory[sPool]).length
		component = Object.create proto, props
		Object.seal component
		return component

	proto[sType] = Factory

	Factory[sPool] = [] # private pool of components
	Factory[symbols.sFields] = fields
	Factory[symbols.sName] = name
	Factory[symbols.sComponentNumber] = componentNumbers[components.size]

	toString = "Component #{name}: " + fields.join ', '
	Factory.toString = -> toString		
	
	Object.freeze Factory
	components.set name, Factory
	return Factory

dispose = ->
	return unless data = this[sData]
	data.length = 0
	this[sType][sPool].push this

reduceField = (fields, field) ->
	return fields unless _.isString(field)
	fields.push field
	return fields

createProps = (props, field, i) ->
	props[field] =
		get: ->
			return this[sData]?[i]
		set: (val) ->
			data = this[sData] or= new Array(this[sType][symbols.sFields].length)
			data[i] = val
		enumerable: yes
	return props