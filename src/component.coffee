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

module.exports = Component = (name, fields) ->
	unless _.isString name 
		throw new TypeError 'missing name of the component'

	# Return existing factory by the name
	return Factory if Factory = components.get name

	if fields and not (_.isArray(fields) and (fields = fast.reduce fields, reduceField, []).length)
		throw new TypeError 'invalid fields specified for component: '+fields

	# log 'component with fields %j has been defined before', fields

	# Create properties based on the fields
	props = Object.create(null)
	fast.reduce fields, createProps, props if fields

	proto = {}
	proto[symbols.sDispose] = dispose

	Factory = ->
		return pool.pop() if (pool = Factory[sPool]).length
		component = Object.create proto, props
		Object.seal component
		return component

	proto[sType] = Factory

	Factory[sPool] = [] # private pool of components
	Factory[symbols.sFields] = fields or emptyFields
	Factory[symbols.sName] = name
	Factory[symbols.sComponentNumber] = do findComponentNumber

	Factory.toString = ->
		"Component #{this.componentName}: " + this[symbols.sFields].join ', '

	components.set name, Factory

	Object.freeze Factory
	return Factory

primes = []
findComponentNumber = ->
	len = primes.length
	pr = primes[len - 1] or 1
	loop
		pr += if len > 2 then 2 else 1
		divides = false
		i = 0
	
		# discard the number if it divides by one earlier prime.
		while i < len
			if (pr % primes[i]) is 0
				divides = true
				break
			i++
		break unless divides is true
	primes.push pr
	return pr

dispose = ->
	return unless data = this[sData]
	data.length = 0
	this[sType][sPool].push this

reduceField = (fields, field) ->
	return fields unless _.isString(field)
	fields.push field
	return fields

createProps = (props, field, i) ->
	props[sData] = writable: yes
	props[field] =
		get: ->
			return this[sData]?[i]
		set: (val) ->
			data = this[sData] or= new Array(this[sType][symbols.sFields].length)
			data[i] = val
		enumerable: yes
	return props