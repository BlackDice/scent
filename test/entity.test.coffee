{expect, sinon, createMockComponent} = require './setup'
Entity = require '../src/entity'
symbols = require '../src/symbols'

NoMe = require 'nome'

describe 'Entity', ->
	
	it 'should be a function', ->
		expect(Entity).to.be.a "function"

	it 'being called returns in instance of entity', ->
		expect(do Entity).to.be.an "object"

	it 'expects optional array of components at first argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /expected array of components/, msg
		toThrow 'string', -> Entity 'str'
		toThrow 'number', -> Entity 1
		toThrow 'bool', -> Entity true
		toThrow 'object', -> Entity {}
		toThrow 'function', -> Entity new Function

	it 'returns new entity instance on every call', ->
		expected = Entity()
		expect(Entity()).to.not.equal expected

	it 'exports `disposed` notifier', ->
		expect(NoMe.is(Entity.disposed)).to.be.true

	it 'exports `componentAdded` notifier', ->
		expect(NoMe.is(Entity.componentAdded)).to.be.true

	it 'exports `componentRemoved` notifier', ->
		expect(NoMe.is(Entity.componentRemoved)).to.be.true

	describe 'instance', ->

		beforeEach ->
			@entity = do Entity
			@cAlpha = createMockComponent()
			@cBeta = createMockComponent()
			@alpha = do @cAlpha
			@beta = do @cBeta

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

			it 'calls notifier componentAdded', ->
				rem = Entity.componentAdded[ NoMe.bNotify ] spy = sinon.spy()
				@entity.add @alpha
				expect(spy).to.have.been.calledOn(@entity).calledWith(@alpha).calledOnce
				Entity.componentAdded[ NoMe.bDenotify ] rem

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

			it 'calls notifier componentAdded', ->
				rem = Entity.componentAdded[ NoMe.bNotify ] spy = sinon.spy()
				@entity.replace @alpha
				expect(spy).to.have.been.calledOn(@entity).calledWith(@alpha).calledOnce
				Entity.componentAdded[ NoMe.bDenotify ] rem

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

			it 'calls notifier componentRemoved', ->
				@entity.add @alpha
				rem = Entity.componentRemoved[ NoMe.bNotify ] spy = sinon.spy()
				@entity.remove @cAlpha
				expect(spy).to.have.been.calledOn(@entity).calledWith(@cAlpha).calledOnce
				Entity.componentRemoved[ NoMe.bDenotify ] rem

		it 'responds to @@dispose method', ->
			expect(@entity[symbols.bDispose]).to.be.a "function"

		describe '@@dispose', ->

			it 'should remove all contained components', ->
				@entity.add @alpha
				@entity.add @beta
				do @entity[ symbols.bDispose ]
				expect(@entity.has @cAlpha).to.be.false
				expect(@entity.has @cBeta).to.be.false

			it 'should call dispose method of all components', ->
				@entity.add @alpha
				@entity.add @beta
				do @entity[ symbols.bDispose ]
				expect(@alpha.disposed).to.be.true
				expect(@alpha.disposed).to.be.true

			it 'store entity into the pool for later retrieval', ->
				expected = do Entity
				do expected[ symbols.bDispose ]
				actual = do Entity
				expect(actual).to.equal expected

			it 'calls notifier for disposal of entity', ->
				rem = Entity.disposed[ NoMe.bNotify ] spy = sinon.spy()
				do @entity[ symbols.bDispose ]
				expect(spy).to.have.been.calledOn(@entity).calledOnce
				Entity.disposed[ NoMe.bDenotify ] rem

		it 'adds components passed in constructor array', ->
			entity = Entity [@alpha, @beta, @beta]
			expect(entity.has @cAlpha).to.be.true
			expect(entity.has @cBeta).to.be.true

		it 'has size property containing number of components in entity', ->
			expect(@entity).to.have.property "size", 0
			@entity.add @alpha
			expect(@entity).to.have.property "size", 1
			@entity.add @beta
			expect(@entity).to.have.property "size", 2
			@entity.remove @cAlpha
			expect(@entity).to.have.property "size", 1

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
