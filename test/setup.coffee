chai = chai or require 'chai'

module and module.exports =
	chai: chai
	expect: chai.expect
	sinon: sinon = require 'sinon'

chai.use require 'sinon-chai'
# chai.use require 'chai-as-promised'

symbols = require '../src/symbols'
primes = require '../src/primes'
Component = require '../src/component'

module.exports.resetComponentIdentities = ->
	Component.identities.length = 0
	Component.identities.push.apply Component.identities, primes.concat([]).reverse()

module.exports.mockSystem = (name = 'test', body) ->
	body = sinon.spy(body) unless body
	body[ symbols.bName ] = name
	return body