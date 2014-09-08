{expect, sinon} = require './setup'
Entity = require '../src/entity'
Component = require '../src/component'
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

		before ->
			@cAlphaComponent = Component 'alpha', 'alphaTest'
			@cBetaComponent = Component 'beta', 'betaTest'

		beforeEach ->
			@entity = do Entity
			@alpha = do @cAlphaComponent
			@beta = do @cBetaComponent

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
				rem = Entity.componentAdded.notify spy = sinon.spy()
				@entity.add @alpha
				expect(spy).to.have.been.calledOn(@entity).calledWith(@alpha).calledOnce
				Entity.componentAdded.denotify rem

			it 'allows component to be added to single entity only', ->
				@entity.add @alpha
				otherEntity = do Entity
				otherEntity.add @alpha
				expect(otherEntity.has @cAlphaComponent).to.be.false

		it 'responds to replace method', ->
			expect(@entity).to.respondTo 'replace'

		describe 'replace()', ->

			it 'should throw error if invalid component passed in', ->
				checkForComponent (val) => @entity.replace val

			it 'should return entity itself', ->
				expect(@entity.add @alpha).to.equal @entity

			it 'should replace existing component', ->
				@entity.add @alpha
				newAlpha = do @cAlphaComponent
				@entity.replace newAlpha
				expect(@entity.get @cAlphaComponent).to.equal newAlpha
				expect(@entity.has @cAlphaComponent).to.be.true

			it 'calls notifier componentAdded', ->
				rem = Entity.componentAdded.notify spy = sinon.spy()
				@entity.replace @alpha
				expect(spy).to.have.been.calledOn(@entity).calledWith(@alpha).calledOnce
				Entity.componentAdded.denotify rem

			it 'allow replaced component to be added in another entity', ->
				@entity.add @alpha
				@entity.replace do @cAlphaComponent
				otherEntity = do Entity
				otherEntity.add @alpha
				expect(otherEntity.has @cAlphaComponent).to.be.true

		it 'responds to has method', ->
			expect(@entity).to.respondTo 'has'

		describe 'has()', ->

			it 'should return false for non-existing component', ->
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'should return true for previously added component', ->
				@entity.add @alpha
				expect(@entity.has @cAlphaComponent).to.be.true

		it 'responds to get method', ->
			expect(@entity).to.respondTo 'get'

		describe 'get()', ->

			it 'should return null for non-existing component', ->
				expect(@entity.get @cAlphaComponent).to.equal null

			it 'should return previously added component', ->
				@entity.add @alpha
				expect(@entity.get @cAlphaComponent).to.equal @alpha

		it 'responds to getAll method', ->
			expect(@entity).to.respondTo 'getAll'

		describe 'getAll()', ->

			it 'should return empty array when no components are present', ->
				expect(result = @entity.getAll()).to.be.an 'array'
				expect(result.length).to.equal 0

			it 'should return array of added components', ->
				@entity.add @alpha
				@entity.add @beta
				expect(result = @entity.getAll()).to.be.an 'array'
				expect(result.length).to.equal 2
				expect(result).to.include @alpha
				expect(result).to.include @beta

			it 'optionally accepts array that will be filled with components', ->
				@entity.add @alpha
				@entity.add @beta
				expected = []
				actual = @entity.getAll expected
				expect(actual).to.equal expected
				expect(actual.length).to.equal 2

		it 'responds to remove method', ->
			expect(@entity).to.respondTo 'remove'

		describe 'remove()', ->

			it 'should not remove anything when non-existing component specified', ->
				@entity.add @alpha
				@entity.remove @cBetaComponent
				expect(@entity.has @cAlphaComponent).to.be.true

			it 'should remove component instance passed', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'should remove component of specified type', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'should call dispose method of removed component by default', ->
				rem = Component.disposed.notify spy = sinon.spy()
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				expect(spy).to.have.been.calledOn(@alpha)
				Component.disposed.denotify rem

			it 'should not call dispose of component if second argument is false', ->
				rem = Component.disposed.notify spy = sinon.spy()
				@entity.add @alpha
				@entity.remove @cAlphaComponent, false
				expect(spy).to.not.have.been.called
				Component.disposed.denotify rem

			it 'calls notifier componentRemoved', ->
				@entity.add @alpha
				rem = Entity.componentRemoved.notify spy = sinon.spy()
				@entity.remove @cAlphaComponent
				expect(spy).to.have.been.calledOn(@entity).calledWith(@cAlphaComponent).calledOnce
				Entity.componentRemoved.denotify rem

			it 'allows removed component to be added in another entity', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				otherEntity = do Entity
				otherEntity.add @alpha
				expect(otherEntity.has @cAlphaComponent).to.be.true

		it 'responds to @@dispose method', ->
			expect(@entity[ symbols.bDispose ]).to.be.a "function"

		describe '@@changed', ->

			beforeEach ->
				@clock = sinon.useFakeTimers @now = Date.now()

			afterEach ->
				@clock.restore()

			it 'should be own property', ->
				expect(@entity[ symbols.bChanged ]).to.exist

			it 'should equal to 0 for a fresh entity', ->
				expect(@entity[ symbols.bChanged ]).to.equal 0

			it 'should equal to current timestamp when component is added', ->
				@entity.add @alpha
				expect(@entity[ symbols.bChanged ]).to.equal @now

			it 'should equal to current timestamp when component is removed', ->
				@entity.remove @cBetaComponent
				expect(@entity[ symbols.bChanged ]).to.equal 0
				@entity.add @alpha
				@clock.tick 500
				@entity.remove @cAlphaComponent
				expect(@entity[ symbols.bChanged ]).to.equal @now + 500

			it 'should be updated when component data has changed', ->
				@entity.add @alpha
				@entity.add @beta
				@clock.tick 500
				@alpha.alphaTest = 10
				expect(@entity[ symbols.bChanged ]).to.equal @now + 500
				@clock.tick 500
				@beta.betaTest = 20
				expect(@entity[ symbols.bChanged ]).to.equal @now + 1000

		describe '@@dispose', ->

			it 'should remove all contained components', ->
				@entity.add @alpha
				@entity.add @beta
				do @entity[ symbols.bDispose ]
				expect(@entity.has @cAlphaComponent).to.be.false
				expect(@entity.has @cBetaComponent).to.be.false

			it 'should call dispose method of all components', ->
				rem = Component.disposed.notify spy = sinon.spy()
				@entity.add @alpha
				@entity.add @beta
				do @entity[ symbols.bDispose ]
				expect(spy).to.have.been.calledOn @alpha
				expect(spy).to.have.been.calledOn @beta
				expect(spy).to.have.been.calledTwice
				Component.disposed.denotify rem

			it 'store entity into the pool for later retrieval', ->
				expected = do Entity
				do expected[ symbols.bDispose ]
				actual = do Entity
				expect(actual).to.equal expected

			it 'calls notifier for disposal of entity', ->
				rem = Entity.disposed.notify spy = sinon.spy()
				do @entity[ symbols.bDispose ]
				expect(spy).to.have.been.calledOn(@entity).calledOnce
				Entity.disposed.denotify rem

			it 'should reset @@changed property for disposed entity', ->
				@entity.add @alpha
				do @entity[ symbols.bDispose ]
				expect(@entity[ symbols.bChanged ]).to.equal 0

		it 'adds components passed in constructor array', ->
			entity = Entity [@alpha, @beta, @beta]
			expect(entity.has @cAlphaComponent).to.be.true
			expect(entity.has @cBetaComponent).to.be.true

		it 'has size property containing number of components in entity', ->
			expect(@entity).to.have.property "size", 0
			@entity.add @alpha
			expect(@entity).to.have.property "size", 1
			@entity.add @beta
			expect(@entity).to.have.property "size", 2
			@entity.remove @cAlphaComponent
			expect(@entity).to.have.property "size", 1

	it 'removes entity components that were disposed', ->

		cComponent = Component 'disposing', 'alpha beta'
		component = do cComponent
		entity = do Entity
		entity.add component
		do component[ symbols.bDispose ]
		expect(entity.has cComponent).to.be.false