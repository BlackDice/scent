log = (require 'debug') 'scent:component'
_ = require 'lodash'
require 'es6'

components = new Set
reserved = ['constructor', 'toString', 'dispose']

module.exports = (fields) ->
	# Convert argument to array if none passed
	fields = [fields] unless _.isArray fields

	# Filter out invalid fields
	fields = fields.reduce reduceField, []

	unless fields.length
		throw new TypeError 'no fields specified for component'

	id = fields.join('|')
	if components.has id
		log 'component with fields %j has been defined before', fields
	else components.add id

	pool = []

	props = fields.reduce createProps, Object.create(null)
	proto = dispose: ->
		return unless this.__data
		this.__data.length = 0
		pool.push this

	Component = ->
		return pool.pop() if pool.length
		component = Object.create proto, props
		Object.seal component
		return component

	proto['constructor'] = Component
	Component.toString = -> 
		"Component #{fields.join ', '}"	

	Object.freeze Component
	return Component

reduceField = (fields, field) ->
	return fields unless _.isString(field)
	if ~reserved.indexOf field
		throw TypeError "specified field #{field} is reserved word, choose another"
	fields.push field
	return fields

createProps = (props, field, i) ->
	props['__data'] = writable: yes
	props[field] =
		get: ->
			return this.__data?[i]
		set: (val) ->
			data = this.__data or= [] 
			data[i] = val
		enumerable: yes
	return props