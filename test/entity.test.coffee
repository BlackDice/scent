{expect, sinon} = require './setup'
Entity = require '../src/entity'
Component = require '../src/component'

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
		expected = Entity(123)
		expect(Entity 123).to.equal expected

	describe 'instance', ->

		beforeEach ->
			@entity = do Entity
			@cAlpha = Component 'alpha'
			@cBeta = Component 'beta'
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

		it 'forbids any modification to its structure or values', ->
			@entity.someProperty = true
			expect(@entity.someProperty).to.not.exist

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

		createFakeComponent = ->
			fakeComponent = Object.create dispose: -> this.disposed = yes
			fakeComponent.disposed = no
			fakeComponent.constructor = Object.freeze(->)
			return fakeComponent

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
				fakeComponent = createFakeComponent()
				@entity.add fakeComponent
				@entity.remove fakeComponent.constructor
				expect(fakeComponent.disposed).to.be.true

			it 'should not call dispose of component if second argument is false', ->
				fakeComponent = createFakeComponent()
				@entity.add fakeComponent
				@entity.remove fakeComponent.constructor, false
				expect(fakeComponent.disposed).to.be.false

		it 'responds to dispose method', ->
			expect(@entity).to.respondTo 'dispose'

		describe 'dispose()', ->

			it 'should remove all contained components', ->
				@entity.add @alpha
				@entity.add @beta
				@entity.dispose()
				expect(@entity.has @cAlpha).to.be.false
				expect(@entity.has @cBeta).to.be.false

			it 'should call dispose method of the component', ->
				fakeComponent = createFakeComponent()
				@entity.add fakeComponent
				@entity.dispose()
				expect(fakeComponent.disposed).to.be.true

		it 'works as expected', ->
			alpha = do @cAlpha
			beta = do @cBeta
			
			@entity.add alpha
			expect(@entity.get @cAlpha).to.equal alpha
			expect(@entity.has @cAlpha).to.be.true
			
			@entity.add beta
			@entity.remove @cAlpha

			expect(@entity.get @cBeta).to.equal beta
			expect(@entity.has @cBeta).to.be.true
