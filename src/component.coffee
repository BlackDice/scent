log = (require 'debug') 'scent:component'
_ = require 'lodash'

require 'es6-shim'
components = new Map

reservedNames = ['entity']
reservedFields = ['componentType', 'dispose']

module.exports = (name, fields) ->
	unless _.isString name 
		throw new TypeError 'missing name of the component'

	if ~reservedNames.indexOf name
		throw new TypeError name + ' is reserved word and cannot be used for component name'

	if fields and not (_.isArray(fields) and (fields = fields.reduce reduceField, []).length)
		throw new TypeError 'invalid fields specified for component: '+fields

	return Component if Component = components.get name

	# log 'component with fields %j has been defined before', fields

	props = Object.create(null)
	proto = {dispose}

	fields?.reduce createProps, props

	Component = ->
		return pool.pop() if (pool = Component.__pool).length
		component = Object.create proto, props
		Object.seal component
		return component

	proto['componentType'] = Component

	Component.__pool = []
	Component.componentFields = fields
	Component.componentName = name
	Component.toString = -> 
		"Component #{this.componentName}: " + this.componentFields?.join ', '

	components.set name, Component

	Object.freeze Component
	return Component

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