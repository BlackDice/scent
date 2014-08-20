{sinon, expect} = require './setup'
Component = require '../src/component'
symbols = require '../src/symbols'

describe 'Component', ->

	afterEach ->
		Component.map.clear()
		Component.identities.length = 0
		Component.identities.push.apply Component.identities, [23, 19, 17, 13, 11, 7, 5, 3, 2]

	it 'should be a function', ->
		expect(Component).to.be.a "function"

	it 'expects name of component in the first argument', ->
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

	it 'optionally expects array of strings passed in second argument', ->
		toThrow = (msg, fn) ->
			expect(fn).to.throw TypeError, /invalid fields/, msg
		toThrow 'number', -> Component 'number', 1
		toThrow 'bool', -> Component 'bool', true
		toThrow 'string', -> Component 'string', 'nothing'
		toThrow 'empty array', -> Component 'empty array', []
		toThrow 'num array', -> Component 'num array', [1]
		toThrow 'bool array', -> Component 'bool array', [true]

	it 'should return a component type function', ->
		expect(Component 'factory').to.be.a "function"

	beforeEach ->
		@fields = ['test1', 'test2', 'test3']

	describe 'type', ->

		it 'should forbid to add custom properties to itself', ->
			cComponent = Component 'forbid'
			cComponent.customProperty
			expect(cComponent).to.not.have.property "customProperty"

		it 'should provide name of component in @@name', ->
			cComponent = Component name = 'withname'
			expect(cComponent[ symbols.bName ]).to.equal name

		it 'should set @@identity property to unique prime number', ->
			cComponent = Component 'genIdentity'
			expect(expected = cComponent[ symbols.bIdentity ]).to.be.a "Number"
			primes = require '../src/primes'
			expect(~primes.indexOf expected).not.to.equal 0
			cComponent2 = Component 'genIdentity2'
			expect(cComponent2[ symbols.bIdentity ]).to.not.equal expected

		it 'can set identity from options object', ->
			cComponent = Component 'withIdentity', identity: expected = 23
			expect(cComponent[ symbols.bIdentity ]).to.equal expected

		it 'forbids to use identity that is a not prime number', ->
			fn = -> Component 'failIdentity', identity: 8
			expect(fn).to.throw Error, /invalid identity/

		it 'forbids to use identity that is already taken', ->
			Component 'test'
			fn = -> Component 'usedIdentity', identity: 2
			expect(fn).to.throw Error, /invalid identity/

		it 'assigns next free identity for the following component', ->
			Component 'test', identity: 2
			expected = Component 'test2'
			expect(expected[ symbols.bIdentity ]).to.equal 3

		it 'should provide list of defined fields in @@fields', ->
			cComponent = Component 'withfields', @fields
			expect(cComponent[ symbols.bFields ]).to.eql @fields

		it 'should filter out duplicate fields', ->
			cComponent = Component 'duplicates', ['dupe', 'dupe']
			expect(cComponent[ symbols.bFields ]).to.eql ['dupe']

		it 'should filter out non-string fields', ->
			cComponent = Component 'mess', ['good', 1, true, {}]
			expect(cComponent[ symbols.bFields ]).to.eql ['good']

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
			expect(@component[symbols.bType]).to.eql @cComponent

		it 'should have properties defined by fields argument', ->
			for field in @fields
				expect(@component).to.have.property field

		it 'should allow to set and get defined property value', ->
			for field, i in @fields
				@component[field] = i
				expect(@component[field]).to.equal i

		it 'of same type should have separate data', ->
			@component.test1 = 10
			component2 = do @cComponent
			component2.test1 = 20
			expect(@component.test1).to.equal 10
			expect(component2.test1).to.equal 20

		it 'should keep values intact when not defined property is set', ->
			for field, i in @fields
				@component[field] = i
			@component.nothing = true
			for field, i in @fields
				expect(@component[field]).to.equal i

		describe '@@changed', ->

			beforeEach ->
				@clock = sinon.useFakeTimers @now = Date.now()

			afterEach ->
				@clock.restore()

			it 'should be own property', ->
				expect(@component[ symbols.bChanged ]).to.exist

			it 'should equal to 0 for a fresh component', ->
				expect(@component[ symbols.bChanged ]).to.equal 0

			it 'should equal to current timestamp when value is set', ->
				@component.test1 = 10
				expect(@component[ symbols.bChanged ]).to.equal @now

			it 'should update timestamp for following data change', ->
				@component.test1 = 10
				@clock.tick 500
				@component.test2 = 20
				expect(@component[ symbols.bChanged ]).to.equal @now + 500

			it 'should not update timestamp when setting unknown property', ->
				@component.test1 = 10
				@clock.tick 500
				@component.test10 = 10
				expect(@component[ symbols.bChanged ]).to.equal @now

		describe '@@dispose', ->

			it 'should be a function', ->
				expect(@component[ symbols.bDispose ]).to.be.an "function"

			it 'should unset all data of the component', ->
				@component.test1 = 'a'
				@component.test3 = 'b'
				do @component[ symbols.bDispose ]
				expect(@component.test1).to.not.be.ok
				expect(@component.test3).to.not.be.ok

			it 'should keep disposed component for next use', ->
				@component.test2 = 'foo'
				do @component[ symbols.bDispose ]
				actual = do @cComponent
				expect(actual).to.equal @component

			it 'should reset @@changed property for disposed component', ->
				@component.test1 = 10
				do @component[ symbols.bDispose ]
				expect(@component[ symbols.bChanged ]).to.equal 0
