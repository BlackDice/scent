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

	it 'returns new entity instance on every call', ->
		expected = do Entity
		expect(do Entity).to.not.equal expected

	it 'expects optional array of components at first argument', ->
		toThrow = (msg, fn) ->
			expect(fn).to.throw TypeError, /expected array of components/, msg
		toThrow 'string', -> Entity 'str'
		toThrow 'number', -> Entity 1
		toThrow 'bool', -> Entity true
		toThrow 'object', -> Entity {}
		toThrow 'function', -> Entity new Function

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

		it 'passes the `instanceof`', ->
		    expect(Entity()).to.be.an.instanceof Entity

		it 'passes `Entity.prototype.isPrototypeOf` check', ->
		    expect(Entity.prototype.isPrototypeOf Entity()).to.be.true

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
				otherEntity = new Entity
				otherEntity.add @alpha
				expect(otherEntity.has @cAlphaComponent).to.be.false

			it 'forbids to override component of the same type', ->
				@entity.add @alpha
				@entity.add new @cAlphaComponent
				expect(@entity.get @cAlphaComponent).to.equal @alpha

			it 'forbids to add component if entity is being disposed', ->
				@entity.dispose()
				@entity.add @alpha
				expect(@entity.size).to.equal 0

		it 'responds to replace method', ->
			expect(@entity).to.respondTo 'replace'

		describe 'replace()', ->

			it 'should throw error if invalid component passed in', ->
				checkForComponent (val) => @entity.replace val

			it 'should return entity itself', ->
				expect(@entity.add @alpha).to.equal @entity

			it 'should replace existing component', ->
				@entity.add @alpha
				newAlpha = new @cAlphaComponent
				@entity.replace newAlpha
				expect(@entity.get @cAlphaComponent).to.equal newAlpha
				expect(@entity.has @cAlphaComponent).to.be.true

			it 'should keep replaced component type in entity when release is called', ->
				@entity.add @alpha
				@entity.replace new @cAlphaComponent
				@entity.release()
				expect(@entity.has @cAlphaComponent).to.be.true

			it 'calls notifier componentAdded', ->
				rem = Entity.componentAdded.notify spy = sinon.spy()
				@entity.replace @alpha
				expect(spy).to.have.been.calledOn(@entity).calledWith(@alpha).calledOnce
				Entity.componentAdded.denotify rem

			it 'allow replaced component to be added in another entity', ->
				@entity.add @alpha
				@entity.replace new @cAlphaComponent
				@entity.release()
				otherEntity = new Entity [@alpha]
				expect(otherEntity.has @cAlphaComponent).to.be.true

			it 'forbids to replace component if entity is being disposed', ->
				@entity.add @alpha
				@entity.dispose()
				@entity.replace new @cAlphaComponent
				expect(@entity.get @cAlphaComponent, true).to.equal @alpha

			it 'ddd', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				@entity.release()
				@entity.replace newAlpha = (new @cAlphaComponent)
				expect(@entity.get @cAlphaComponent).to.equal newAlpha

		it 'responds to has method', ->
			expect(@entity).to.respondTo 'has'

		describe 'has()', ->

			it 'should throw error if invalid component type passed in', ->
				checkForComponentType (val) => @entity.has val

			it 'should return false for non-existing component', ->
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'should return true for previously added component', ->
				@entity.add @alpha
				expect(@entity.has @cAlphaComponent).to.be.true

			it 'should return false if component is being disposed', ->
				@entity.add @alpha
				do @alpha[ symbols.bDispose ]
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'should return true for disposed component if true is passed in second argument', ->
				@entity.add @alpha
				do @alpha[ symbols.bDispose ]
				expect(@entity.has @cAlphaComponent, true).to.be.true

		it 'responds to get method', ->
			expect(@entity).to.respondTo 'get'

		describe 'get()', ->

			it 'should throw error if invalid component type passed in', ->
				checkForComponentType (val) => @entity.get val

			it 'should return null for non-existing component', ->
				expect(@entity.get @cAlphaComponent).to.be.null

			it 'should return previously added component', ->
				@entity.add @alpha
				expect(@entity.get @cAlphaComponent).to.equal @alpha

			it 'should return null if component is being disposed', ->
				@entity.add @alpha
				do @alpha[ symbols.bDispose ]
				expect(@entity.get @cAlphaComponent).to.be.null

			it 'should return disposed component if true is passed in second argument', ->
				@entity.add @alpha
				do @alpha[ symbols.bDispose ]
				expect(@entity.get @cAlphaComponent, true).to.equal @alpha

		it 'responds to remove method', ->
			expect(@entity).to.respondTo 'remove'

		describe 'remove()', ->

			it 'should throw error if invalid component type passed in', ->
				checkForComponentType (val) => @entity.remove val

			it 'should dispose component instance of passed component type', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'should remove only specified component type', ->
				@entity.add @alpha
				@entity.remove @cBetaComponent
				expect(@entity.size).to.equal 1

			it 'should call @@dispose method of removed component by default', ->
				rem = Component.disposed.notify spy = sinon.spy()
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				expect(spy).to.have.been.calledOn(@alpha)
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
				@entity.release()
				otherEntity = new Entity [@alpha]
				expect(otherEntity.has @cAlphaComponent).to.be.true

			it 'allows to add component of the same type after release is called', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				@entity.add newAlpha = (new @cAlphaComponent)
				@entity.release()
				expect(@entity.has @cAlphaComponent).to.be.true
				expect(@entity.get @cAlphaComponent).to.equal newAlpha

		describe 'changed', ->

			beforeEach ->
				@clock = sinon.useFakeTimers @now = Date.now()

			afterEach ->
				@clock.restore()

			it 'should be own property', ->
				expect(@entity.changed).to.exist

			it 'should equal to 0 for a fresh entity', ->
				expect(@entity.changed).to.equal 0

			it 'should equal to current timestamp when component is added', ->
				@entity.add @alpha
				expect(@entity.changed).to.equal @now

			it 'should equal to current timestamp when component is removed', ->
				@entity.remove @cBetaComponent
				expect(@entity.changed).to.equal 0
				@entity.add @alpha
				@clock.tick 500
				@entity.remove @cAlphaComponent
				expect(@entity.changed).to.equal @now + 500

			it 'should equal to current timestamp when component is replaced', ->
				@entity.add @alpha
				@clock.tick 500
				@entity.replace new @cAlphaComponent
				expect(@entity.changed).to.equal @now + 500

			it 'should be updated when component data has changed', ->
				@entity.add @alpha
				@entity.add @beta
				@clock.tick 500
				@alpha.alphaTest = 10
				expect(@entity.changed).to.equal @now + 500
				@clock.tick 500
				@beta.betaTest = 20
				expect(@entity.changed).to.equal @now + 1000

		it 'responds to `dispose` method', ->
			expect(@entity).to.respondTo 'dispose'

		describe 'dispose()', ->

			it 'should call dispose method of all components', ->
				rem = Component.disposed.notify spy = sinon.spy()
				@entity.add @alpha
				@entity.add @beta
				@entity.dispose()
				expect(spy).to.have.been.calledOn @alpha
				expect(spy).to.have.been.calledOn @beta
				expect(spy).to.have.been.calledTwice
				Component.disposed.denotify rem

			it 'calls notifier for disposal of entity', ->
				rem = Entity.disposed.notify spy = sinon.spy()
				@entity.dispose()
				expect(spy).to.have.been.calledOn(@entity).calledOnce
				Entity.disposed.denotify rem

		it 'responds to `release` method', ->
			expect(@entity).to.respondTo 'release'

		describe 'release()', ->

			it 'removes and releases all contained components when entity is disposed', ->
				@entity.add @alpha
				@alpha.alphaTest = 10
				@entity.add @beta
				@beta.betaTest = 20
				@entity.dispose()
				@entity.release()
				expect(@entity.has @cAlphaComponent).to.be.false
				expect(@entity.has @cBetaComponent).to.be.false
				expect(@alpha.alphaTest).to.not.be.ok
				expect(@beta.betaTest).to.not.be.ok

			it 'resets disposing flag for entity', ->
				@entity.dispose()
				@entity.release()
				expect(@entity).to.not.have.property symbols.bDispsing

			it 'should reset `changed` property to 0', ->
				@entity.add @alpha
				@entity.dispose()
				@entity.release()
				expect(@entity.changed).to.equal 0

			it 'removes components from entity that were removed', ->
				@entity.add @alpha
				@entity.remove @cAlphaComponent
				@entity.release()
				expect(@entity.has @cAlphaComponent).to.be.false

			it 'removes releases components that were replaced', ->
				@entity.add @alpha
				@alpha.alphaTest = 10
				@entity.replace new @cAlphaComponent
				@entity.release()
				expect(@alpha.alphaTest).to.not.be.ok

			it 'removes entity components that were disposed', ->
				cComponent = Component 'disposing', 'alpha beta'
				component = new cComponent
				entity = new Entity [component]
				do component[ symbols.bDispose ]
				entity.release()
				expect(entity.has cComponent, true).to.be.false

		it 'adds components passed in constructor array', ->
			entity = Entity [@alpha, @beta]
			expect(entity.has @cAlphaComponent).to.be.true
			expect(entity.has @cBetaComponent).to.be.true

		it 'has size property containing number of components in entity', ->
			expect(@entity).to.have.property "size", 0
			@entity.add @alpha
			expect(@entity).to.have.property "size", 1
			@entity.add @beta
			expect(@entity).to.have.property "size", 2
			@entity.remove @cAlphaComponent
			@entity.release()
			expect(@entity).to.have.property "size", 1

	it 'responds to getAll method', ->
		expect(Entity).itself.to.respondTo 'getAll'

	describe 'getAll()', ->

		beforeEach ->
			@entity = new Entity
			@alpha = new (@cAlpha = Component 'alpha')
			@beta = new (@cBeta = Component 'beta')
			@getAll = Entity.getAll.bind @entity

		it 'expects to be called in context of Entity instance', ->
			expect(Entity.getAll).to.throw TypeError, /expected entity/

		it 'returns empty array when no components are present on entity', ->
			actual = @getAll()
			expect(actual).to.be.an 'array'
			expect(actual.length).to.equal 0

		it 'returns array of all present components', ->
			@entity.add @alpha
			@entity.add @beta
			actual = @getAll()
			expect(actual).to.be.an 'array'
			expect(actual.length).to.equal 2
			expect(actual).to.include @alpha
			expect(actual).to.include @beta

		it 'uses array passed in first argument for results', ->
			@entity.add @alpha
			@entity.add @beta
			expected = []
			actual = @getAll expected
			expect(actual).to.equal expected
			expect(actual.length).to.equal 2

	it 'responds to `pooled` method', ->
		expect(Entity).itself.to.respondTo 'pooled'

	describe 'pooled()', ->

		it 'returns new entity instance', ->
			expect(Entity.pooled()).to.be.an.instanceof Entity

		it 'returns entity instance that was released up before', ->
			expected = new Entity
			expected.dispose()
			expect(Entity.pooled()).to.not.equal expected
			expected.release()
			expect(Entity.pooled()).to.equal expected
