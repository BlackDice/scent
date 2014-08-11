{expect, createMockComponent, mockEntity} = require './setup'
System = require '../src/system'
symbols = require '../src/symbols'

describe 'System', ->
	
	it 'should be a function', ->
		expect(System).to.be.a "function"

	it 'expects name of system as string first argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /expected name/, msg
		toThrow 'void', -> System()
		toThrow 'null', -> System null
		toThrow 'number', -> System 1
		toThrow 'bool', -> System true
		toThrow 'array', -> System []
		toThrow 'object', -> System {}
		toThrow 'object', -> System new Function

	it 'expects function as system initializer at second argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /expected function/, msg
		toThrow 'void', -> System 'test'
		toThrow 'null', -> System 'test', null
		toThrow 'string', -> System 'test', 'str'
		toThrow 'number', -> System 'test', 1
		toThrow 'bool', -> System 'test', true
		toThrow 'array', -> System 'test', []
		toThrow 'object', -> System 'test', {}

	it 'returns system initializer function', ->
		expected = ->
		expect(System 'test', expected).to.equal expected

	it 'sets @@name property on returned function', ->
		actual = System name = 'test', ->
		expect(actual[ symbols.bName ]).to.equal name
