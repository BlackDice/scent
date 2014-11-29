{expect} = require './setup'
System = require '../src/system'
symbols = require '../src/symbols'

describe 'System', ->

	it 'should be an object', ->
		expect(System).to.be.an "object"

	it 'should respond to `define` method', ->
		expect(System).itself.to.respondTo 'define'

	describe 'define', ->

		it 'expects name of system as string first argument', ->
			toThrow = (msg, fn) ->
				expect(fn).to.throw TypeError, /expected name/, msg
			toThrow 'void', -> System.define()
			toThrow 'null', -> System.define null
			toThrow 'number', -> System.define 1
			toThrow 'bool', -> System.define true
			toThrow 'array', -> System.define []
			toThrow 'object', -> System.define {}
			toThrow 'object', -> System.define new Function

		it 'expects function as system initializer at second argument', ->
			toThrow = (msg, fn) ->
				expect(fn).to.throw TypeError, /expected function/, msg
			toThrow 'void', -> System.define 'test'
			toThrow 'null', -> System.define 'test', null
			toThrow 'string', -> System.define 'test', 'str'
			toThrow 'number', -> System.define 'test', 1
			toThrow 'bool', -> System.define 'test', true
			toThrow 'array', -> System.define 'test', []
			toThrow 'object', -> System.define 'test', {}

		it 'returns system initializer function', ->
			expected = ->
			expect(System.define 'test', expected).to.equal expected

		it 'sets @@name property on returned function', ->
			actual = System.define name = 'test', ->
			expect(actual[ symbols.bName ]).to.equal name
