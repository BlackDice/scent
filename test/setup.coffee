chai = chai or require 'chai'

module and module.exports = 
	chai: chai
	expect: chai.expect
	sinon: require 'sinon'

chai.use require 'sinon-chai'
# chai.use require 'chai-as-promised'

symbols = require '../src/symbols'
componentNumbers = require '../src/component-number'
called = 0
module.exports.createMockComponent = (name) ->
	Component = ->
		component = Object.create(null) 
		component[ symbols.sDispose ] = -> this.disposed = yes
		component[ symbols.sType ] = Component
		component.disposed = no
		return component
	Component[ symbols.sNumber ] = componentNumbers[called++]
	Component[ symbols.sName ] = name or 'mock'
	Object.freeze Component
	return Component

module.exports.mockEntity = (components...) ->
	entity = 
		get: (componentType) ->
			for component in components
				return component if componentType is component[ symbols.sType ]
			return null
		add: (component) ->
			componentType = component[ symbols.sType ]
			oldComponent = this.get componentType
			if oldComponent and ~(idx = (components.indexOf oldComponent))
				components[idx] = component
			return this
		remove: (componentType) ->
			componentToRemove = this.get componentType
			if ~(idx = (components.indexOf componentToRemove))
				components.splice idx, 1
			return this

	entity[ symbols.sNodes ] = new Map
	return entity