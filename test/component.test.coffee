{expect} = require './setup'
Component = require '../src/component'

describe 'Component', ->
	it 'should be a function', ->
		expect(Component).to.be.a "function"

	it 'expects at least one field name passed in first argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /no fields/, msg
		toThrow 'void', Component
		toThrow 'null', -> Component null
		toThrow 'number', -> Component 1
		toThrow 'bool', -> Component true
		toThrow 'empty array', -> Component []
		toThrow 'num array', -> Component [1]
		toThrow 'bool array', -> Component [true]

		expect(-> Component 'test').to.not.throw
		expect(-> Component ['test']).to.not.throw
		expect(-> Component [1, 'test']).to.not.throw

	it 'should return a function used to create component', ->
		expect(Component 'test').to.be.a "function"

	it 'should return same function for the identical fields passed in', ->
		expected = Component 'test'
		expect(Component 'test').to.equal expected

	describe 'constructor', ->

		beforeEach ->
			@fields = ['test1', 'test2', 'test3']
			@component = Component @fields

		it 'should return new object upon calling', ->
			expected = do @component
			expect(expected).to.be.an 'object'
			expect(do @component).to.not.equal expected

		it 'should be set as constructor on returned object', ->
			actual = do @component
			expect(actual).to.have.property "constructor", @component

		it 'should have properties defined by fields argument', ->
			actual = do @component
			for field in @fields
				expect(actual).to.have.property field

		it 'should allow to set and retrieve property value', ->
			actual = do @component
			for field, i in @fields
				actual[field] = i + 10
				expect(actual).to.have.property field, i + 10

		it 'should forbid to set properties out of defined set', ->
			actual = do @component
			actual.fail = yes
			expect(actual).to.not.have.property "fail"
