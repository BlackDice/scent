{sinon, expect} = require './setup'
Component = require '../src/component'
symbols = require '../src/symbols'

xdescribe 'Component', ->

	before ->
		@validFields = 'x test1 test2 test3'
		@fieldsArray = @validFields.split ' '
		@validName = 'name'
		@resetIdentities = ->
			Component.identities.length = 0
			Component.identities.push.apply Component.identities, [23, 19, 17, 13, 11, 7, 5, 3, 2]

	beforeEach ->
		@resetIdentities()

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
		toThrow 'function', -> Component new Function

	it 'optionally expects string passed in second argument', ->
		toThrow = (msg, fn) ->
			expect(fn).to.throw TypeError, /expected string/, msg
		toThrow 'number', -> Component 'number', 1
		toThrow 'bool', -> Component 'bool', false
		toThrow 'array', -> Component 'array', []
		toThrow 'object', -> Component 'object', {}
		toThrow 'function', -> Component 'function', new Function

		expect(-> Component 'null', null).to.not.throw

	it 'returns a component type function', ->
		expect(Component 'name').to.be.a "function"

	it 'returns a new function for every call', ->
		expected = Component 'name'
		actual = Component 'name'
		expect(actual).to.not.equal expected

	it 'returns second argument when component type passed', ->
		expected = Component 'name'
		expect(Component 'name', expected).to.equal expected

	describe 'type', ->

		it 'passes the `instanceof` check toward the Component function', ->
			expect(Component @validName).to.be.an.instanceof Component

		it 'passes `Component.prototype.isPrototypeOf` check', ->
			expect(Component.prototype.isPrototypeOf Component @validName).to.be.true

		it 'forbids to add custom properties to itself', ->
			cComponent = Component @validName, @validFields
			cComponent.customProperty = true
			expect(cComponent).to.not.have.property "customProperty"

		it 'should provide name of component type in read-only @@name property', ->
			cComponent = Component @validName, @validFields
			cComponent[ symbols.bName ] = "fakeName"
			expect(cComponent[ symbols.bName ]).to.equal @validName

		it 'should provide defined fields as array in read-only @@fields property', ->
			check = (input, output) ->
				comp = Component 'name', input
				comp[ symbols.bFields ] = false
				expect(comp[ symbols.bFields ]).to.eql output

			check @validFields, @fieldsArray
			check 'MoreSpace  2Tab		gAmA   #nope $not aaa-bbb', ['MoreSpace', 'gAmA']
			check 'duplicate duplicate duplicate', ['duplicate']

		it 'should provide identity number as prime number in read-only @@identity property', ->
			cComponent = Component @validName, @validFields
			expect(expected = cComponent[ symbols.bIdentity ]).to.be.a "Number"
			primes = require '../src/primes'
			expect(~primes.indexOf expected).not.to.equal 0
			cComponent2 = Component @validName
			expect(cComponent2[ symbols.bIdentity ]).to.not.equal expected

		it 'uses identity number #23 from fields definition', ->
			check = (input) =>
				cComponent = Component @validName, input
				expect(cComponent[ symbols.bIdentity ]).to.equal 23
				@resetIdentities()

			check @validFields + ' #23'
			check '#23 ' + @validFields
			check 'test #23 #2 test2'

		it 'forbids to use identity that is a not prime number', ->
			fn = -> Component 'failIdentity', '#8'
			expect(fn).to.throw Error, /invalid identity/

		it 'forbids to use identity that is already taken', ->
			Component 'given2'
			fn = -> Component 'specified2', '#2'
			expect(fn).to.throw Error, /invalid identity/

		it 'assigns next free identity to the following component', ->
			Component 'specified5', '#5'
			cExpected = Component 'expected2'
			expect(cExpected[ symbols.bIdentity ]).to.equal 2

		it 'should provide component definition in @@definition property', ->
			def = 'alpha beta gama'
			cComponent = Component 'test', def
			expect(cComponent[ symbols.bDefinition ]).to.equal "#2 #{def}"

		it 'should expose list of defined properties when calling toString()', ->
			cComponent = Component @validName, @validFields
			stringified = cComponent.toString()
			for field in @fieldsArray
				expect(stringified).to.contain field

		it 'should return component instance upon calling', ->
			cComponent = Component 'instance'
			expected = do cComponent
			expect(expected).to.be.an 'object'
			expect(do cComponent).to.not.equal expected

	describe 'instance', ->

		beforeEach ->
			@cComponent = Component @validName, @validFields
			@component = do @cComponent

		it 'passes the `instanceof` check toward the defined type function', ->
			expect(@component).to.be.an.instanceof @cComponent

		it 'passes `cComponent.prototype.isPrototypeOf` check', ->
			expect(@cComponent.prototype.isPrototypeOf @component).to.be.true

		it 'should provide component type function in read-only @@type property', ->
			@component = do @cComponent
			expect(@component[ symbols.bType ]).to.equal @cComponent

		it 'should provide properties defined by fields definition', ->
			for field in @fieldsArray
				expect(@component).to.have.property field

		it 'should allow to set and get defined property value', ->
			for field, i in @fieldsArray
				@component[field] = i
				expect(@component[field]).to.equal i

		it 'of same type should have separate data', ->
			@component.test1 = 10
			component2 = do @cComponent
			component2.test1 = 20
			expect(@component.test1).to.equal 10
			expect(component2.test1).to.equal 20

		it 'should keep values intact when not defined property is set', ->
			for field, i in @fieldsArray
				@component[field] = i
			@component.nothing = true
			for field, i in @fieldsArray
				expect(@component[field]).to.equal i

		it 'should set values based on array passed into function', ->
			component = @cComponent [5, 10, 20, 30]
			expect(component.test1).to.equal 10
			expect(component.test2).to.equal 20
			expect(component.test3).to.equal 30

		it 'should keep values undefined when passed array is shorter', ->
			component = @cComponent [5, 10, 20]
			expect(component.test1).to.equal 10
			expect(component.test2).to.equal 20
			expect(component.test3).to.not.be.ok

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
