{sinon, expect} = require './setup'
{Action, Entity, Symbols} = Scent

describe 'Action', ->

	before ->
		@validName = 'name'

	it 'should be a function', ->
		expect(Action).to.be.a "function"

	it 'expects name of action in the first argument', ->
		toThrow = (msg, fn) ->
			expect(fn).to.throw TypeError, /expected name/, msg
		toThrow 'void', Action
		toThrow 'null', -> Action null

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

		it 'should provide name of action type in @@name property', ->
			aAction = Action @validName
			expect(aAction[ Symbols.bName ]).to.equal @validName

		it 'responds to `trigger` method', ->
			expect(Action @validName).to.respondTo 'trigger'

		it 'triggered action object is returned from `trigger` call', ->
			expect(Action(@validName).trigger()).to.be.an "object"

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
			aType.trigger()
			aType.trigger()
			aType.each spy = sinon.spy()
			expect(spy).to.have.been.calledTwice

		it 'provides `time` property equal to timestamp of action triggering', ->
			aType = Action @validName
			clock = sinon.useFakeTimers expected = Date.now()
			aType.trigger()
			clock.tick 500
			aType.each (action) ->
				expect(action.time).to.equal expected
			clock.restore()

		it 'provides `type` property equal to owning action type', ->
			aType = Action @validName
			aType.trigger()
			aType.each (action) ->
				expect(action).to.have.property 'type', aType

		it 'provides `data` property equal to first argument from trigger call', ->
			aType = Action @validName
			aType.trigger expected = a: 10, b: false, c: "test"
			aType.each (action) ->
				expect(action).to.have.property 'data', expected

		it 'provides `meta` property equal to second argument from trigger call', ->
			aType = Action @validName
			aType.trigger null, expected = a: 10, b: false, c: "test"
			aType.each (action) ->
				expect(action).to.have.property 'meta', expected

		it 'provides `get` method that allows to retrieve property value from data argument', ->
			aType = Action @validName
			action = aType.trigger expected = a: 10, b: false, c: "test"
			expect(action.get('a')).to.equal expected.a
			expect(action.get('b')).to.equal expected.b
			expect(action.get('c')).to.equal expected.c

		it 'provides `set` method for setting properties on data object', ->
			aType = Action @validName
			action = aType.trigger()
			action.set('test', expected = 200)
			expect(action.get('test')).to.equal expected

		it 'provides `size` property with number of currently triggered actions', ->
			aType = Action @validName
			aType.trigger()
			aType.trigger()
			expect(aType.size).to.equal 2
			aType.finish()
			expect(aType.size).to.equal 0

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
			aType.trigger Entity() # more actions should be added
			aType.each spy = sinon.spy()
			expect(spy).to.have.been.calledTwice # got action from the buffer + new one
