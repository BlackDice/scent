{expect, createMockComponent} = require './setup'
Entity = require '../src/entity'
symbols = require '../src/symbols'

describe 'Entity', ->
	
	it 'should be a function', ->
		expect(Entity).to.be.a "function"

	it 'being called returns in instance of entity', ->
		expect(do Entity).to.be.an "object"

	it 'expects string or number or nothing at first argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /invalid id/, msg
		toThrow 'bool', -> Entity true
		toThrow 'array', -> Entity []
		toThrow 'object', -> Entity {}
		toThrow 'function', -> Entity new Function

	it 'returns same value for the identical first argument', ->
		expected = Entity(1)
		expect(Entity 1).to.equal expected

	describe 'instance', ->

		beforeEach ->
			@entity = do Entity
			@cAlpha = createMockComponent()
			@cBeta = createMockComponent()
			@alpha = do @cAlpha
			@beta = do @cBeta

		it 'has read-only id property when first argument passed in', ->
			entityWithId = Entity 200
			entityWithId.id = 100
			expect(entityWithId).to.have.ownProperty "id", 200

		it 'has read-only property @@nodes being the map', ->
			expect(@entity[ symbols.sNodes ]).to.be.an.instanceof Map

		it 'forbids any modification to its structure or values', ->
			@entity.someProperty = true
			expect(@entity.someProperty).to.not.exist

		checkForComponent = (method) ->
			expect(method).to.throw TypeError, /missing component/
			checkForComponentType method

		checkForComponentType = (method) ->
			toThrow = (msg, fn) ->
				expect(fn).to.throw TypeError, /invalid component/, msg
			toThrow 'bool', -> method true
			toThrow 'number', -> method 1
			toThrow 'string', -> method "foo"
			toThrow 'function', -> method new Function
			toThrow 'array', -> method []
			toThrow 'object', -> method {}

		it 'responds to add method', ->
			expect(@entity).to.respondTo 'add'

		describe 'add()', ->

			it 'should throw error if invalid component passed in', ->
				checkForComponent (val) => @entity.add val

			it 'should return entity itself', ->
				expect(@entity.add @alpha).to.equal @entity

		it 'responds to replace method', ->
			expect(@entity).to.respondTo 'replace'

		describe 'replace()', ->

			it 'should throw error if invalid component passed in', ->
				checkForComponent (val) => @entity.replace val

			it 'should return entity itself', ->
				expect(@entity.add @alpha).to.equal @entity

			it 'should replace existing component', ->
				@entity.add @alpha
				newAlpha = do @cAlpha
				@entity.replace newAlpha
				expect(@entity.get @cAlpha).to.equal newAlpha
				expect(@entity.has @cAlpha).to.be.true

		it 'responds to has method', ->
			expect(@entity).to.respondTo 'has'

		describe 'has()', ->

			it 'should throw error if invalid component type passed in', ->
				checkForComponentType (val) => @entity.has val

			it 'should return false for non-existing component', ->
				expect(@entity.has @cAlpha).to.be.false

			it 'should return true for previously added component', ->
				@entity.add @alpha
				expect(@entity.has @cAlpha).to.be.true

		it 'responds to get method', ->
			expect(@entity).to.respondTo 'get'

		describe 'get()', ->

			it 'should throw error if invalid component type passed in', ->
				checkForComponentType (val) => @entity.get val

			it 'should return null for non-existing component', ->
				expect(@entity.get @cAlpha).to.equal null

			it 'should return previously added component', ->
				@entity.add @alpha
				expect(@entity.get @cAlpha).to.equal @alpha

		it 'responds to remove method', ->
			expect(@entity).to.respondTo 'remove'

		describe 'remove()', ->

			it 'should throw error if invalid component type passed in', ->
				checkForComponentType (val) => @entity.remove val

			it 'should not remove anything when non-existing component specified', ->
				@entity.add @alpha
				@entity.remove @cBeta
				expect(@entity.has @cAlpha).to.be.true

			it 'should remove component of specified type', ->
				@entity.add @alpha
				@entity.remove @cAlpha
				expect(@entity.has @cAlpha).to.be.false

			it 'should call dispose method of removed component by default', ->
				@entity.add @alpha
				@entity.remove @cAlpha
				expect(@alpha.disposed).to.be.true

			it 'should not call dispose of component if second argument is false', ->
				@entity.add @alpha
				@entity.remove @cAlpha, false
				expect(@alpha.disposed).to.be.false

		it 'responds to @@dispose method', ->
			expect(@entity[symbols.sDispose]).to.be.a "function"

		describe '@@dispose', ->

			it 'should remove all contained components', ->
				@entity.add @alpha
				@entity.add @beta
				do @entity[symbols.sDispose]
				expect(@entity.has @cAlpha).to.be.false
				expect(@entity.has @cBeta).to.be.false

			it 'should call dispose method of all components', ->
				@entity.add @alpha
				@entity.add @beta
				do @entity[symbols.sDispose]
				expect(@alpha.disposed).to.be.true
				expect(@alpha.disposed).to.be.true

			it 'stored entity into the pool with no id is specified', ->
				expected = do Entity
				do expected[symbols.sDispose]
				actual = do Entity
				expect(actual).to.equal expected

			it 'trashes entity with id specified', ->
				expected = Entity 'trash'
				do expected[symbols.sDispose]
				actual = Entity 'trash'
				expect(actual).to.not.equal expected

		it 'works as expected', ->
			@entity.add @alpha
			expect(@entity.get @cAlpha).to.equal @alpha
			expect(@entity.has @cAlpha).to.be.true
			
			newAlpha = do @cAlpha
			@entity.replace newAlpha
			expect(@entity.get @cAlpha).to.equal newAlpha

			@entity.add @beta
			@entity.remove @cAlpha

			expect(@entity.get @cBeta).to.equal @beta
			expect(@entity.has @cBeta).to.be.true
