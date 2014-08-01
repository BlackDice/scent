log = (require 'debug') 'scent:component'
_ = require 'lodash'
require 'es6'

components = new Set

module.exports = (fields) ->
	# Convert argument to array if none passed
	fields = [fields] unless _.isArray fields

	# Filter out non-string values
	fields = fields.filter _.isString

	unless fields.length
		throw new TypeError 'no fields specified for component'

	id = fields.join('|')
	if components.has id
		log 'component with fields %j has been defined before', fields
	components.add id

	props = fields.reduce createProps, Object.create(null)

	Component = ->
		component = Object.create null, props
		component.constructor = Component
		Object.seal component
		return component

	Component.toString = ->
		"Component #{fields.join ', '}"

	Object.freeze Component
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