_ = require 'lodash'
require 'es6'

components = new Map

module.exports = (fields) ->
	# Convert argument to array if none passed
	fields = [fields] unless _.isArray fields

	# Filter out non-string values
	fields = fields.filter _.isString

	unless fields.length
		throw new TypeError 'no fields specified for component'

	id = fields.join '|'

	# Try to get component function from the map first
	return components.get id if components.has id

	props = fields.reduce createProps, Object.create(null)

	Component = (componentData) ->
		component = Object.create null, props
		component.constructor = Component
		Object.seal component
		return component
	
	components.set id, Component
	return Component

createProps = (props, field, i) ->
	props['__data'] = writable: yes
	props[field] =
		get: ->
			return this.__data?[i] or null
		set: (val) ->
			data = this.__data or= [] 
			data[i] = val
		enumerable: yes
	return props