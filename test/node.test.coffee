{expect, createMockComponent, mockEntity, sinon} = require './setup'
Node = require '../src/node'
symbols = require '../src/symbols'

describe 'Node', ->
	
	it 'should be a function', ->
		expect(Node).to.be.a "function"

	it 'expects array or single component at first argument', ->
		toThrow = (msg, fn) -> 
			expect(fn).to.throw TypeError, /invalid component/, msg
		toThrow 'number', -> Node 1
		toThrow 'bool', -> Node true
		toThrow 'string', -> Node 'nothing'
		toThrow 'object', -> Node {}

		toThrowMissing = (msg, fn) -> 
			expect(fn).to.throw TypeError, /component for node/, msg
		toThrowMissing 'empty array', -> Node []
		toThrowMissing 'num array', -> Node [1]
		toThrowMissing 'bool array', -> Node [true]
		toThrowMissing 'object array', -> Node [{}]

	it 'being called returns node list object', ->
		expect(Node [createMockComponent()]).to.be.an "object"

	it 'returns same node list for identical component set', ->
		scheme = [createMockComponent(), createMockComponent(), createMockComponent()]
		expected = Node scheme
		actual = Node scheme.reverse()
		expect(actual).to.equal expected

	it 'returns different note list for different component set', ->
		expected = Node [createMockComponent()]
		actual = Node [createMockComponent()]
		expect(actual).to.not.equal expected

	it 'forbids modification to node list structure', ->
		nNode = Node [createMockComponent()]
		nNode[expected = 'donotaddthis'] = true
		expect(nNode).not.to.have.ownProperty expected

	describe 'list', ->

		beforeEach ->
			@cAlphaComponent = createMockComponent('alpha')
			@cBetaComponent = createMockComponent('beta')
			@nNode = Node [@cAlphaComponent, @cBetaComponent]
			@createEntity = =>
				mockEntity (@alpha = do @cAlphaComponent), (@beta = do @cBetaComponent)
			@entity = @createEntity()

		afterEach ->
			@nNode.each (node) => @nNode.removeEntity node[ symbols.sEntity ] 

		expectEntity = (nodeList, fnName) ->
			toThrow = (msg, fn) -> 
				expect(fn).to.throw TypeError, /invalid entity/, msg
			
			toThrow 'number', -> nodeList[fnName] 1
			toThrow 'bool', -> nodeList[fnName] true
			toThrow 'string', -> nodeList[fnName] 'nothing'
			toThrow 'object', -> nodeList[fnName] {}
			toThrow 'array', -> nodeList[fnName] []

		it 'responds to `addEntity` method', ->
			expect(@nNode).to.respondTo 'addEntity'

		describe 'addEntity()', ->

			beforeEach ->
				@badEntity = mockEntity (do createMockComponent('fail'))

			it 'expects one argument with entity or array of entities', ->
				expectEntity @nNode, 'addEntity'

			it 'adds compatible entities to the list', ->
				@nNode.addEntity @entity
				expect(@nNode.size).to.equal 1
				otherEntity = @createEntity()
				@nNode.addEntity otherEntity
				expect(@nNode.size).to.equal 2

			it 'keeps incompatible entities out of the list', ->
				@nNode.addEntity @badEntity
				expect(@nNode.size).to.equal 0

			it 'silently ignores entities that are already on the list', ->
				@nNode.addEntity @entity
				@nNode.addEntity @entity
				expect(@nNode.size).to.equal 1

			it 'returns node list itself', ->
				expect(@nNode.addEntity @entity).to.equal @nNode
				expect(@nNode.addEntity @entity).to.equal @nNode
				expect(@nNode.addEntity @badEntity).to.equal @nNode

			describe 'added item', ->

				beforeEach ->
					@nNode.addEntity @entity
					@item = @nNode.head

				it 'has @@entity property equal to added entity', ->
					expect(@item[ symbols.sEntity ]).to.equal @entity

				it 'has @@type property equal to parent node list', ->
					expect(@item[ symbols.sType ]).to.equal @nNode

				it 'has properties based on components names in the set ', ->
					expect(@item).to.have.property @cAlphaComponent[ symbols.sName ], @alpha
					expect(@item).to.have.property @cBetaComponent[ symbols.sName ], @beta

				it 'should be stored in @@nodes map within entity object', ->
					expect(@entity[ symbols.sNodes ].has(@nNode)).to.be.true
					expect(@entity[ symbols.sNodes ].get(@nNode)).to.equal @nNode.head

		it 'responds to `removeEntity` method', ->
			expect(@nNode).to.respondTo 'removeEntity'

		describe 'removeEntity()', ->

			beforeEach ->
				@nNode.addEntity @entity

			it 'expects one argument with entity or array of entities', ->
				expectEntity @nNode, 'removeEntity'

			it 'removes item from the list when it has been added before', ->
				otherEntity = @createEntity()
				missingEntity = @createEntity()
				@nNode.addEntity otherEntity
				@nNode.removeEntity @entity
				expect(@nNode.size).to.equal 1
				expect(@nNode.head[ symbols.sEntity ]).to.equal otherEntity
				@nNode.removeEntity missingEntity
				expect(@nNode.size).to.equal 1
				@nNode.removeEntity otherEntity
				expect(@nNode.size).to.equal 0

			it 'returns node list itself', ->
				missingEntity = @createEntity()
				expect(@nNode.removeEntity @entity).to.equal @nNode
				expect(@nNode.removeEntity missingEntity).to.equal @nNode

			it 'should remove itself from the entity\'s @@nodes map', ->
				@nNode.removeEntity @entity
				expect(@entity[ symbols.sNodes ].has(@nNode)).to.be.false

			it 'removes entity reference from @@entity property', ->
				item = @nNode.head
				@nNode.removeEntity @entity
				expect(item[ symbols.sEntity ]).to.equal null

		it 'responds to `updateEntity` method', ->
			expect(@nNode).to.respondTo 'updateEntity'

		describe 'updateEntity()', ->

			it 'expects one argument with entity or array of entities', ->
				expectEntity @nNode, 'updateEntity'

			it 'adds entity if not on the list and it\'s compatible', ->
				@nNode.updateEntity @entity
				expect(@nNode.head[ symbols.sEntity ]).to.equal @entity

			it 'updates component references to current ones', ->
				@nNode.addEntity @entity
				@entity.add (newAlpha = do @cAlphaComponent)
				@nNode.updateEntity @entity
				expect(@nNode.size).to.equal 1
				expect(@nNode.head).to.have.property @cAlphaComponent[ symbols.sName ], newAlpha

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
				expect(spy.firstCall.args[0][ symbols.sEntity ]).to.equal @entity
				expect(spy.firstCall.args[1]).to.equal 0
				expect(spy.secondCall.args[0][ symbols.sEntity ]).to.equal otherEntity
				expect(spy.secondCall.args[1]).to.equal 1

			it 'optionally accepts third argument being context for the callback function', ->
				@nNode.addEntity @entity
				spy = sinon.spy()
				@nNode.each spy, ctx = {}
				expect(spy).to.be.calledOn ctx
