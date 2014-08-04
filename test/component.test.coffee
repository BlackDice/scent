{expect} = require './setup'
Component = require '../src/component'
symbols = require '../src/symbols'

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

	it 'should return same value for identical name', ->
		expected = Component 'name'
		expect(Component 'name').to.equal expected

	it 'optionally expects array of string passed in second argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /invalid fields/, msg
		toThrow 'number', -> Component 'number', 1
		toThrow 'bool', -> Component 'bool', true
		toThrow 'string', -> Component 'string', 'nothing'
		toThrow 'empty array', -> Component 'empty array', []
		toThrow 'num array', -> Component 'num array', [1]
		toThrow 'bool array', -> Component 'bool array', [true]
		toThrow 'object', -> Component 'object', {}

	it 'should return a factory function used to create component', ->
		expect(Component 'factory').to.be.a "function"

	beforeEach ->
		@fields = ['test1', 'test2', 'test3']

	describe 'factory', ->

		it 'should forbid to add custom properties to itself', ->
			cComponent = Component 'forbid'
			cComponent.customProperty
			expect(cComponent).to.not.have.property "customProperty"

		it 'should provide name of component in @@name', ->
			cComponent = Component name = 'withname'
			expect(cComponent[symbols.sName]).to.equal name

		it 'should provide unique number of component in property @@componentNumber', ->
			cComponent = Component 'hashed'
			expect(cComponent[symbols.sComponentNumber]).to.be.a "Number"
			cComponent2 = Component 'hashed2'
			expect(cComponent2[symbols.sComponentNumber]).to.not.equal cComponent[symbols.componentNumber]
		
		it 'should provide list of defined fields in @@fields', ->
			cComponent = Component 'withfields', @fields
			expect(cComponent[symbols.sFields]).to.eql @fields

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

		it 'should have a factory function stored in @@type', ->
			expect(@component[symbols.sType]).to.eql @cComponent

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

		describe '@@dispose', ->

			it 'should be a function', ->
				expect(@component[symbols.sDispose]).to.be.an "function"

			it 'should destroy component completely if no data were set', ->
				do @component[symbols.sDispose]
				newComponent = do @cComponent
				expect(newComponent).to.not.equal @component

			it 'should unset all data of the component', ->
				@component.test1 = 'a'
				@component.test3 = 'b'
				do @component[symbols.sDispose]
				expect(@component.test1).to.not.be.ok
				expect(@component.test3).to.not.be.ok

			it 'should keep disposed component for next use', ->
				@component.test2 = 'foo'
				do @component[symbols.sDispose]
				actual = do @cComponent
				expect(actual).to.equal @component