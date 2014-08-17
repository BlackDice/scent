chai = chai or require 'chai'

module and module.exports = 
	chai: chai
	expect: chai.expect
	sinon: sinon = require 'sinon'

chai.use require 'sinon-chai'
# chai.use require 'chai-as-promised'

symbols = require '../src/symbols'

primes = require '../src/primes'
components = 0

module.exports.createMockComponent = (name) ->
	Component = ->
		component = Object.create(null) 
		component[ symbols.bDispose ] = -> this.disposed = yes
		component[ symbols.bType ] = Component
		component.disposed = no
		return component
	Component[ symbols.bIdentity ] = primes[components++]
	Component[ symbols.bName ] = name or 'mock'
	Object.freeze Component
	return Component

module.exports.mockEntity = (components...) ->
	entity = 
		get: (componentType) ->
			for component in components
				return component if componentType is component[ symbols.bType ]
			return null
		add: (component) ->
			componentType = component[ symbols.bType ]
			oldComponent = this.get componentType
			if oldComponent and ~(idx = (components.indexOf oldComponent))
				components[idx] = component
			return this
		remove: (componentType) ->
			componentToRemove = this.get componentType
			if ~(idx = (components.indexOf componentToRemove))
				components.splice idx, 1
			return this

	entity[ symbols.bNodes ] = new Map
	return entity

module.exports.mockSystem = (name = 'test', body) ->
	body = sinon.spy(body) unless body
	body[ symbols.bName ] = name
	return body