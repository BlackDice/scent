chai = chai or require 'chai'

module and module.exports = 
	chai: chai
	expect: chai.expect
	sinon: require 'sinon'

chai.use require 'sinon-chai'
chai.use require 'chai-as-promised'

symbols = require '../src/symbols'
componentNumbers = require '../src/component-number'
called = 0
module.exports.createMockComponent = (name) ->
	Component = ->
		component = Object.create(null) 
		component[symbols.sDispose] = -> this.disposed = yes
		component[symbols.sType] = Component
		component.disposed = no
		return component
	Component[symbols.sComponentNumber] = componentNumbers[called++]
	Component[symbols.sName] = name or 'mock'
	Object.freeze Component
	return Component