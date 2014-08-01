{expect} = require './setup'
Component = require '../src/component'

describe 'Component', ->
	
	it 'should be a function', ->
		expect(Component).to.be.a "function"

	it 'expects string or array of at least one string passed in first argument', ->
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

	it 'should throw error when specified field is reserved word', ->
		expect(-> Component 'constructor').to.throw TypeError, /reserved word/
		expect(-> Component 'dispose').to.throw TypeError, /reserved word/

	it 'should return a constructor function used to create component', ->
		expect(Component 'test').to.be.a "function"

	beforeEach ->
		@fields = ['test1', 'test2', 'test3']

	describe 'factory', ->

		beforeEach ->
			@cComponent = Component @fields

		it 'should forbid to add custom properties to itself', ->
			@cComponent.customProperty
			expect(@cComponent).to.not.have.property "customProperty"

		it 'should expose list of defined properties when calling toString()', ->
			for field in @fields
				expect(@cComponent.toString()).to.contain field

		it 'should return new object upon calling', ->
			expected = do @cComponent
			expect(expected).to.be.an 'object'
			expect(do @cComponent).to.not.equal expected

	describe 'instance', ->

		beforeEach ->
			@cComponent = Component @fields
			@component = do @cComponent

		it 'should have a constructor function stored in constructor property', ->
			expect(@component).to.have.property "constructor", @cComponent

		it 'should have properties defined by fields argument', ->
			for field in @fields
				expect(@component).to.have.ownProperty field

		it 'should allow to get and set property value', ->
			for field, i in @fields
				@component[field] = i
				expect(@component[field]).to.equal i

		it 'should forbid to set properties out of defined set', ->
			@component.fail = yes
			expect(@component).to.not.have.property "fail"

		describe 'dispose()', ->

			it 'should be a function', ->
				expect(@component).to.respondTo 'dispose'

			it 'should unset all data of component', ->
				@component.test1 = 'a'
				@component.test3 = 'b'
				@component.dispose()
				expect(@component.test1).to.not.be.ok
				expect(@component.test3).to.not.be.ok

			it 'should destroy component completely if no data were set', ->
				@component.dispose()
				newComponent = do @cComponent
				expect(newComponent).to.not.equal @component