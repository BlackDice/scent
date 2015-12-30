{expect, sinon} = require './setup'
{Node, Entity, Component, Symbols} = Scent

describe 'NodeType', ->

	beforeEach ->
		(require './setup').resetComponentIdentities()
		@cComponent = Component 'test'

	it 'should be a function', ->
		expect(Node).to.be.a "function"

	it 'expects array or single component at first argument', ->

		toThrow = (msg, fn) ->
			expect(fn).to.throw TypeError, /at least one component type/, msg
		toThrow 'number', -> new Node 1
		toThrow 'bool', -> new Node true
		toThrow 'string', -> new Node 'nothing'
		toThrow 'object', -> new Node {}
		toThrow 'empty array', -> new Node []
		toThrow 'num array', -> new Node [1]
		toThrow 'bool array', -> new Node [true]
		toThrow 'object array', -> new Node [{}]

	it 'returns new node type object for each call', ->
		actual = new Node @cComponent
		expect(actual).to.be.an "object"
		expected = new Node [@cComponent]
		expect(expected).to.not.equal actual

	describe 'type', ->

		beforeEach ->
			@cAlphaComponent = Component('alpha')
			@cBetaComponent = Component('beta')
			@nNode = Node [@cAlphaComponent, @cBetaComponent]
			@createEntity = (comps) =>
				comps ?= [new @cAlphaComponent, new @cBetaComponent]
				return new Entity comps
			@entity = @createEntity [
				@alpha = new @cAlphaComponent
				@beta = new @cBetaComponent
			]

		afterEach ->
			@nNode.each (node) => @nNode.removeEntity node[ Symbols.bEntity ]

		expectEntity = (nodeList, fnName) ->
			toThrow = (msg, fn) ->
				expect(fn).to.throw TypeError, /invalid entity/, msg

			toThrow 'number', -> nodeList[fnName] 1
			toThrow 'bool', -> nodeList[fnName] true
			toThrow 'string', -> nodeList[fnName] 'nothing'
			toThrow 'object', -> nodeList[fnName] {}
			toThrow 'array', -> nodeList[fnName] []

		it 'ignores duplicate component types', ->
			nNode = Node [@cAlphaComponent, @cAlphaComponent]
			expect(nNode.types).to.have.length 1

		it 'invokes passed componentProvider for non-component', ->
			componentProvider = stub = sinon.stub()
			stub.returns @cAlphaComponent
			nNode = Node ['alpha', @cBetaComponent], componentProvider
			expect(stub).to.have.been.calledOnce.calledWith 'alpha'

		it 'ignores component types that componentProvider failed to provide', ->
			componentProvider = stub = sinon.stub()
			stub.returns null
			nNode = Node [@cAlphaComponent, 'none'], componentProvider
			expect(nNode.types).to.have.length 1
			expect(nNode.types[0]).to.be.equal @cAlphaComponent

		it 'responds to `addEntity` method', ->
			expect(@nNode).to.respondTo 'addEntity'

		describe 'addEntity()', ->

			it 'expects one argument with entity', ->
				expectEntity @nNode, 'addEntity'

			it 'adds compatible entities to the list', ->
				@nNode.addEntity @entity
				expect(@nNode.size).to.equal 1
				otherEntity = @createEntity()
				@nNode.addEntity otherEntity
				expect(@nNode.size).to.equal 2

			it 'keeps incompatible entities out of the list', ->
				badEntity = new Entity [new (Component 'bad')]
				@nNode.addEntity badEntity
				expect(@nNode.size).to.equal 0

			it 'silently ignores entities that are already on the list', ->
				@nNode.addEntity @entity
				@nNode.addEntity @entity
				expect(@nNode.size).to.equal 1

			it 'returns node type itself', ->
				expect(@nNode.addEntity @entity).to.equal @nNode
				expect(@nNode.addEntity @entity).to.equal @nNode
				expect(@nNode.addEntity new Entity).to.equal @nNode

			describe 'added item', ->

				beforeEach ->
					@nNode.addEntity @entity
					@item = @nNode.head

				it 'has @@entity property equal to added entity', ->
					expect(@item[ Symbols.bEntity ]).to.equal @entity

				it 'has @@type property equal to parent node type', ->
					expect(@item[ Symbols.bType ]).to.equal @nNode

				it 'has properties based on components names in the set ', ->
					expect(@item).to.have.property @cAlphaComponent.typeName, @alpha
					expect(@item).to.have.property @cBetaComponent.typeName, @beta

		it 'responds to `removeEntity` method', ->
			expect(@nNode).to.respondTo 'removeEntity'

		describe 'removeEntity()', ->

			beforeEach ->
				@nNode.addEntity @entity

			it 'expects one argument with entity', ->
				expectEntity @nNode, 'removeEntity'

			it 'removes item that no longer fits components constrains', ->
				@nNode.removeEntity @entity
				expect(@nNode.size).to.equal 1
				expect(@nNode.head.entityRef).to.equal @entity
				@entity.remove @cBetaComponent
				@nNode.removeEntity @entity
				expect(@nNode.size).to.equal 0

			it 'returns node type itself', ->
				missingEntity = @createEntity()
				expect(@nNode.removeEntity @entity).to.equal @nNode
				expect(@nNode.removeEntity missingEntity).to.equal @nNode

		it 'responds to `updateEntity` method', ->
			expect(@nNode).to.respondTo 'updateEntity'

		describe 'updateEntity()', ->

			it 'expects one argument with entity', ->
				expectEntity @nNode, 'updateEntity'

			it 'adds entity if not on the list and it\'s compatible', ->
				@nNode.updateEntity @entity
				expect(@nNode.head[ Symbols.bEntity ]).to.equal @entity

			it 'updates component references to current ones', ->
				@nNode.addEntity @entity
				@entity.replace newAlpha = (new @cAlphaComponent)
				@nNode.updateEntity @entity
				expect(@nNode.size).to.equal 1
				expect(@nNode.head).to.have.property @cAlphaComponent.typeName, newAlpha

			it 'removes entity if it\'s no longer compatible', ->
				@nNode.addEntity @entity
				@entity.remove @cAlphaComponent
				@nNode.updateEntity @entity
				expect(@nNode.size).to.equal 0

			it 'returns node list itself', ->
				expect(@nNode.updateEntity @entity).to.equal @nNode
				expect(@nNode.updateEntity @entity).to.equal @nNode
				@entity.remove @cAlphaComponent
				expect(@nNode.updateEntity @entity).to.equal @nNode

		it 'has property `head` set to null', ->
			expect(@nNode).to.have.property 'head', null

		it 'has property `tail` set to null', ->
			expect(@nNode).to.have.property 'tail', null

		it 'has property `types` with component types', ->
			expect(@nNode).to.have.property 'types'
			actual = @nNode.types
			expected = [@cAlphaComponent, @cBetaComponent]
			expect(actual[0]).to.equal expected[0]
			expect(actual[1]).to.equal expected[1]

		it 'responds to `each` method', ->
			expect(@nNode).to.respondTo 'each'

		describe 'each()', ->

			it 'expects callback function in first argument', ->
				nNode = @nNode
				toThrow = (msg, fn) ->
					expect(fn).to.throw TypeError, /callback function/, msg
				toThrow 'void', -> nNode.each()
				toThrow 'null', -> nNode.each null
				toThrow 'number', -> nNode.each 1
				toThrow 'bool', -> nNode.each true
				toThrow 'string', -> nNode.each 'nothing'
				toThrow 'string', -> nNode.each {}
				toThrow 'string', -> nNode.each []

			it 'calls callback for every item in the list in order', ->
				@nNode.addEntity @entity
				@nNode.addEntity otherEntity = @createEntity()
				spy = sinon.spy()
				@nNode.each spy
				expect(spy).to.have.been.calledTwice
				expect(spy.firstCall.args[0][ Symbols.bEntity ]).to.equal @entity
				expect(spy.firstCall.args[1]).to.equal 0
				expect(spy.secondCall.args[0][ Symbols.bEntity ]).to.equal otherEntity
				expect(spy.secondCall.args[1]).to.equal 1

			it 'passes any additional arguments to callback with node item being first', ->
				@nNode.addEntity @entity
				spy = sinon.spy()
				@nNode.each spy, x = 1, y = 2
				expect(spy).to.be.calledWith(
					sinon.match.object
					x, y
				)

		it 'responds to `find` method', ->
			expect(@nNode).to.respondTo 'find'

		describe 'find()', ->

			it 'expects predicate function in first argument', ->
				nNode = @nNode
				toThrow = (msg, fn) ->
					expect(fn).to.throw TypeError, /predicate function/, msg
				toThrow 'void', -> nNode.find()
				toThrow 'null', -> nNode.find null
				toThrow 'number', -> nNode.find 1
				toThrow 'bool', -> nNode.find true
				toThrow 'string', -> nNode.find 'nothing'
				toThrow 'string', -> nNode.find {}
				toThrow 'string', -> nNode.find []

			it 'calls predicate for every item in the list till match is found', ->
				@nNode.addEntity @entity
				@nNode.addEntity otherEntity = @createEntity()
				@nNode.addEntity extraEntity = @createEntity()
				stub = sinon.stub()
				stub.onSecondCall().returns(true)
				@nNode.find stub
				expect(stub).to.have.been.calledTwice
				expect(stub.firstCall.args[0][ Symbols.bEntity ]).to.equal @entity
				expect(stub.firstCall.args[1]).to.equal 0
				expect(stub.secondCall.args[0][ Symbols.bEntity ]).to.equal otherEntity
				expect(stub.secondCall.args[1]).to.equal 1

			it 'passes any additional arguments to predicate with node item being first', ->
				@nNode.addEntity @entity
				spy = sinon.spy()
				@nNode.find spy, x = 1, y = 2
				expect(spy).to.be.calledWith(
					sinon.match.object
					x, y
				)

		it 'responds to `finish` method', ->
			expect(@nNode).to.respondTo 'finish'

		it 'responds to `onAdded` method', ->
			expect(@nNode).to.respondTo 'onAdded'

		describe 'onAdded()', ->

			it 'expects callback function', ->
				{onAdded} = @nNode
				toThrow = (msg, fn) ->
					expect(fn).to.throw TypeError, /callback function/, msg
				toThrow 'void', -> onAdded()
				toThrow 'null', -> onAdded null
				toThrow 'number', -> onAdded 1
				toThrow 'bool', -> onAdded true
				toThrow 'string', -> onAdded 'nothing'
				toThrow 'string', -> onAdded {}
				toThrow 'string', -> onAdded []

			it 'invokes callback for every created node item when finish() is called', ->
				@nNode.onAdded spy = sinon.spy()
				@nNode.addEntity @entity
				expect(spy).to.not.have.been.called
				@nNode.finish()
				expect(spy).to.have.been.calledOnce
				expect(spy.firstCall.args[0][ Symbols.bEntity ]).to.equal @entity
				spy.reset()
				@nNode.finish()
				expect(spy).to.not.have.been.called

			it 'invokes all callbacks for every created node item when finish() is called', ->
				@nNode.onAdded spy = sinon.spy()
				@nNode.onAdded spy2 = sinon.spy()
				@nNode.addEntity @entity
				@nNode.finish()
				expect(spy).to.have.been.calledOnce
				expect(spy2).to.have.been.calledOnce

		it 'responds to `onRemoved` method', ->
			expect(@nNode).to.respondTo 'onRemoved'

		describe 'onRemoved()', ->

			it 'expects callback function', ->
				{onRemoved} = @nNode
				toThrow = (msg, fn) ->
					expect(fn).to.throw TypeError, /callback function/, msg
				toThrow 'void', -> onRemoved()
				toThrow 'null', -> onRemoved null
				toThrow 'number', -> onRemoved 1
				toThrow 'bool', -> onRemoved true
				toThrow 'string', -> onRemoved 'nothing'
				toThrow 'string', -> onRemoved {}
				toThrow 'string', -> onRemoved []

			it 'invokes callback for every removed node item when finish() is called', ->
				@nNode.onRemoved spy = sinon.spy()
				@nNode.addEntity @entity
				expect(spy).to.not.have.been.called
				@entity.remove @cAlphaComponent
				@nNode.removeEntity @entity
				expect(spy).to.not.have.been.called
				@nNode.finish()
				expect(spy).to.have.been.calledOnce
				spy.reset()
				@nNode.finish()
				expect(spy).to.not.have.been.called

			it 'invokes all callbacks for every removed node item when finish() is called', ->
				@nNode.onRemoved spy = sinon.spy()
				@nNode.onRemoved spy2 = sinon.spy()
				@nNode.addEntity @entity
				@entity.remove @cAlphaComponent
				@nNode.removeEntity @entity
				@nNode.finish()
				expect(spy).to.have.been.calledOnce
				expect(spy2).to.have.been.calledOnce

			it 'keeps access to data of removed components', (done) ->
				@nNode.addEntity @entity
				@nNode.onRemoved (nodeItem) =>
					expect(nodeItem).to.have.property @cAlphaComponent.typeName, @alpha
					done()
				@entity.remove @cAlphaComponent
				@nNode.removeEntity @entity
				@nNode.finish()