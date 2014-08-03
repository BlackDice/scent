log = (require 'debug') 'scent:component'
_ = require 'lodash'

require 'es6-shim'
components = new Map

reservedFields = ['componentType', 'dispose']

module.exports = Component = (name, fields) ->
	unless _.isString name 
		throw new TypeError 'missing name of the component'

	if ~Component.reservedNames.indexOf name
		throw new TypeError name + ' is reserved word and cannot be used for component name'

	if fields and not (_.isArray(fields) and (fields = fields.reduce reduceField, []).length)
		throw new TypeError 'invalid fields specified for component: '+fields

	return Factory if Factory = components.get name

	# log 'component with fields %j has been defined before', fields

	props = Object.create(null)
	proto = {dispose}

	fields?.reduce createProps, props

	Factory = ->
		return pool.pop() if (pool = Factory.__pool).length
		component = Object.create proto, props
		Object.seal component
		return component

	proto['componentType'] = Factory

	Factory.__pool = []
	Factory.componentFields = fields
	Factory.componentName = name
	Factory.toString = -> 
		"Component #{this.componentName}: " + this.componentFields?.join ', '

	components.set name, Factory

	Object.freeze Factory
	return Factory

Component.reservedNames = []

dispose = ->
	return unless this.__data
	this.__data.length = 0
	this.componentType.__pool.push this

reduceField = (fields, field) ->
	return fields unless _.isString(field)
	if ~reservedFields.indexOf field
		throw TypeError "specified field #{field} is reserved word, choose another"
	fields.push field
	return fields

createProps = (props, field, i) ->
	props['__data'] = writable: yes
	props[field] =
		get: ->
			return this.__data?[i]
		set: (val) ->
			data = this.__data or= new Array(this.componentType.componentFields.length)
			data[i] = val
		enumerable: yes
	return props