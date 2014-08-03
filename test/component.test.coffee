{expect} = require './setup'
Component = require '../src/component'

describe 'Component', ->
	
	it 'should be a function', ->
		expect(Component).to.be.a "function"

	it 'expects name of component for the first argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /missing name/, msg
		toThrow 'void', Component
		toThrow 'null', -> Component null
		toThrow 'number', -> Component 1
		toThrow 'bool', -> Component true
		toThrow 'array', -> Component []
		toThrow 'object', -> Component {}

	it 'forbids name of component to be string entity', ->
		expect(-> Component 'entity').to.throw TypeError, /reserved word/

	it 'should return same value for identical name', ->
		expected = Component 'name'
		expect(Component 'name').to.equal expected

	it 'optionally expects array of string passed in second argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /invalid fields/, msg
		toThrow 'number', -> Component 'name', 1
		toThrow 'bool', -> Component 'name', true
		toThrow 'string', -> Component 'name', 'nothing'
		toThrow 'empty array', -> Component 'name', []
		toThrow 'num array', -> Component 'name', [1]
		toThrow 'bool array', -> Component 'name', [true]
		toThrow 'object', -> Component 'name', {}

	it 'should throw error when specified field is reserved word', ->
		expect(-> Component 'name', ['componentType']).to.throw TypeError, /reserved word/
		expect(-> Component 'name', ['dispose']).to.throw TypeError, /reserved word/

	it 'should return a factory function used to create component', ->
		expect(Component 'factory').to.be.a "function"

	beforeEach ->
		@fields = ['test1', 'test2', 'test3']

	describe 'factory', ->

		it 'should forbid to add custom properties to itself', ->
			cComponent = Component 'forbid'
			cComponent.customProperty
			expect(cComponent).to.not.have.property "customProperty"

		it 'should provide name of component in property componentName', ->
			cComponent = Component name = 'withname'
			expect(cComponent).to.have.ownProperty "componentName"
			expect(cComponent.componentName).to.equal name

		it 'should provide list of defined fields property componentFields', ->
			cComponent = Component 'withfields', @fields
			expect(cComponent).to.have.ownProperty "componentFields"
			expect(cComponent.componentFields).to.eql @fields

		it 'should expose list of defined properties when calling toString()', ->
			cComponent = Component 'toString', @fields
			stringified = cComponent.toString()
			for field in @fields
				expect(stringified).to.contain field

		it 'should return new object upon calling', ->
			cComponent = Component 'instance'
			expected = do cComponent
			expect(expected).to.be.an 'object'
			expect(do cComponent).to.not.equal expected

	describe 'instance', ->

		beforeEach ->
			@cComponent = Component 'test', @fields
			@component = do @cComponent

		it 'should have a factory function stored in property componentType', ->
			expect(@component).to.have.property "componentType", @cComponent

		it 'should have properties defined by fields argument', ->
			for field in @fields
				expect(@component).to.have.ownProperty field

		it 'should allow to get and set defined property value', ->
			for field, i in @fields
				@component[field] = i
				expect(@component[field]).to.equal i

		it 'should forbid to set properties out of defined set', ->
			@component.fail = yes
			expect(@component).to.not.have.property "fail"

		describe 'dispose()', ->

			it 'should be a function', ->
				expect(@component).to.respondTo 'dispose'

			it 'should destroy component completely if no data were set', ->
				@component.dispose()
				newComponent = do @cComponent
				expect(newComponent).to.not.equal @component

			it 'should unset all data of the component', ->
				@component.test1 = 'a'
				@component.test3 = 'b'
				@component.dispose()
				expect(@component.test1).to.not.be.ok
				expect(@component.test3).to.not.be.ok

			it 'should keep disposed component for next use', ->
				@component.test2 = 'foo'
				@component.dispose()
				actual = do @cComponent
				expect(actual).to.equal @component