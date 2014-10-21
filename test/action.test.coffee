{sinon, expect} = require './setup'
Action = require '../src/action'
Entity = require '../src/entity'
symbols = require '../src/symbols'

describe.only 'Action', ->

	before ->
		@validName = 'name'

	it 'should be a function', ->
		expect(Action).to.be.a "function"

	it 'expects name of action in the first argument', ->
		toThrow = (msg, fn) ->
			expect(fn).to.throw TypeError, /missing name/, msg
		toThrow 'void', Action
		toThrow 'null', -> Action null
		toThrow 'number', -> Action 1
		toThrow 'bool', -> Action true
		toThrow 'array', -> Action []
		toThrow 'object', -> Action {}
		toThrow 'function', -> Action new Function

	it 'returns an action type object', ->
		expect(Action @validName).to.be.a "object"

	it 'returns a new object for every call', ->
		expected = Action @validName
		actual = Action @validName
		expect(actual).to.not.equal expected

	describe 'type', ->

		it 'passes the `instanceof` check toward the Action function', ->
			expect(Action @validName).to.be.an.instanceof Action

		it 'passes `Action.prototype.isPrototypeOf` check', ->
			expect(Action.prototype.isPrototypeOf Action @validName).to.be.true

		it 'forbids to add custom properties to itself', ->
			aAction = Action @validName
			aAction.customProperty = true
			expect(aAction).to.not.have.property "customProperty"

		it 'should provide name of action type in read-only @@name property', ->
			aAction = Action @validName
			aAction[ symbols.bName ] = "fakeName"
			expect(aAction[ symbols.bName ]).to.equal @validName

		it 'responds to `trigger` method', ->
			expect(Action @validName).to.respondTo 'trigger'

		it 'responds to `each` method', ->
			expect(Action @validName).itself.to.respondTo 'each'

		it 'each() expects function in the first argument', ->
			each = Action(@validName).each
			toThrow = (msg, fn) ->
				expect(fn).to.throw TypeError, /expected iterator/, msg
			toThrow 'void', each
			toThrow 'null', -> each null
			toThrow 'string', -> each 'test'
			toThrow 'number', -> each 1
			toThrow 'bool', -> each true
			toThrow 'array', -> each []
			toThrow 'object', -> each {}

		it 'responds to `finish` method', ->
			expect(Action @validName).itself.to.respondTo 'finish'

		it 'allows to loop triggered actions with each method', ->
			aType = Action @validName
			aType.trigger Entity()
			aType.trigger Entity()
			aType.each spy = sinon.spy()
			expect(spy).to.have.been
				.calledTwice
				.calledOn spy
				.calledWith sinon.match.array

		it 'provides `entity` property with entity object passed in trigger call', ->
			aType = Action @validName
			aType.trigger entity = Entity()
			aType.each (action) ->
				expect(action.entity).to.equal entity

		it 'sets `entity` property to null if first argument is not entity', ->
			aType = Action @validName
			aType.trigger 1
			aType.each (action) ->
				expect(action.entity).to.equal null

		it 'provides `time` property equal to timestamp of action triggering', ->
			aType = Action @validName
			clock = sinon.useFakeTimers expected = Date.now()
			aType.trigger Entity()
			clock.tick 500
			aType.each (action) ->
				expect(action.time).to.equal expected
			clock.restore()

		it 'provides additional arguments from trigger call during loop as an array', ->
			aType = Action @validName
			aType.trigger Entity(), a = 10, b = false, c = "test"
			aType.each (action) ->
				expect(action.length).to.equal 3
				expect(action[0]).to.equal a
				expect(action[1]).to.equal b
				expect(action[2]).to.equal c

		it 'shifts arguments by one if passed entity is invalid', ->
			aType = Action @validName
			aType.trigger 10, 20
			aType.each (action) ->
				expect(action.length).to.equal 2
				expect(action[0]).to.equal 10
				expect(action[1]).to.equal 20

		it 'provides properties of first argument object through `get` method', ->
			aType = Action @validName
			aType.trigger Entity(), expected = a: 10, b: false, c: "test"
			aType.each (action) ->
				expect(action).itself.to.respondTo 'get'
				expect(action.get 'a').to.equal expected.a
				expect(action.get 'b').to.equal expected.b
				expect(action.get 'c').to.equal expected.c

		it 'clears the list when `finish` is invoked', ->
			aType = Action @validName
			aType.trigger Entity()
			aType.trigger Entity()
			aType.each -> # makes action type frozen
			aType.finish()
			aType.each spy = sinon.spy()
			expect(spy).to.not.have.been.called

		it 'keeps list of actions frozen until `finish` is called', ->
			aType = Action @validName
			aType.trigger Entity()
			aType.each spy = sinon.spy()
			aType.trigger Entity() # this action should be buffered
			expect(spy).to.have.been.calledOnce
			aType.finish() # buffer is flushed
			spy.reset()
			aType.each spy
			expect(spy).to.have.been.calledOnce # got action from the buffer

