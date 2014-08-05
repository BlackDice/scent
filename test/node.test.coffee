{expect, createMockComponent, mockEntity} = require './setup'
Node = require '../src/node'
symbols = require '../src/symbols'

describe 'Node', ->
	
	mockComponentA = createMockComponent('alpha', ['foo'])
	mockComponentB = createMockComponent('beta', ['baz'])
	scheme = [mockComponentA, mockComponentB]

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

	it 'being called returns node type object', ->
		expect(Node scheme).to.be.an "object"

	it 'returns same node type for identical component set', ->
		expected = Node scheme
		actual = Node scheme.reverse()
		expect(actual).to.equal expected

	it 'returns different note type for different component set', ->
		expected = Node scheme
		actual = Node [mockComponentA]
		expect(actual).to.not.equal expected

	it 'forbids modification to node type structure', ->
		node = Node scheme
		node[expected = 'donotaddthis'] = true
		expect(node).not.to.have.ownProperty expected

	describe 'list', ->

		beforeEach ->
			@nodeList = Node scheme

		expectEntity = (nodeList, fnName) ->
			toThrow = (msg, fn) -> 
				expect(fn).to.throw TypeError, /invalid entity/, msg
			
			toThrow 'number', -> nodeList[fnName] 1
			toThrow 'bool', -> nodeList[fnName] true
			toThrow 'string', -> nodeList[fnName] 'nothing'
			toThrow 'object', -> nodeList[fnName] {}
			toThrow 'array', -> nodeList[fnName] []

		it 'responds to `addEntity` method', ->
			expect(@nodeList).to.respondTo 'addEntity'

		it 'addEntity() expects one argument with entity or array of entities', ->
			expectEntity @nodeList, 'addEntity'

		it 'responds to `removeEntity` method', ->
			expect(@nodeList).to.respondTo 'removeEntity'

		it 'removeEntity() expects one argument with entity or array of entities', ->
			expectEntity @nodeList, 'removeEntity'

		it 'responds to `updateEntity` method', ->
			expect(@nodeList).to.respondTo 'updateEntity'

		it 'updateEntity() expects one argument with entity or array of entities', ->
			expectEntity @nodeList, 'updateEntity'

		it 'has property `head` set to null', ->
			expect(@nodeList).to.have.property 'head', null

		it 'has property `tail` set to null', ->
			expect(@nodeList).to.have.property 'tail', null

		it 'responds to `each` method', ->
			expect(@nodeList).to.respondTo 'each'

		it 'sets head and tail to identical node items upon adding entity', ->
			cComponent = createMockComponent()
			nNode = Node [cComponent]
			entity = mockEntity (component = do cComponent)
			nNode.addEntity entity
			expect(nNode.head).to.be.an "object"
			expect(nNode.tail).to.be.an "object"
			expect(nNode.head).to.equal nNode.tail

		it 'sets head and tail to different node items when more valid entities added', ->
			cComponent = createMockComponent()
			nNode = Node [cComponent]
			entity1 = mockEntity (component = do cComponent)
			nNode.addEntity entity1
			entity2 = mockEntity (component = do cComponent)
			nNode.addEntity entity2
			expect(nNode.head).to.not.equal nNode.tail
			expect(nNode.head[ symbols.sEntity]).to.equal entity1
			expect(nNode.tail[ symbols.sEntity]).to.equal entity2

		it 'has no node item added when incompatible entity added', ->
			cComponent = createMockComponent()
			nNode = Node [cComponent, mockComponentA]
			entity = mockEntity (component = do cComponent)
			nNode.addEntity entity
			expect(nNode.head).to.equal null
			expect(nNode.tail).to.equal null

	describe 'item', ->

		it 'has @@entity equal to added compatible entity', ->
			nNode = Node scheme
			entity = mockEntity (do mockComponentA), (do mockComponentB)
			nNode.addEntity entity
			expect(nNode.head[ symbols.sEntity ]).to.equal entity

		it 'has properties based on components names in the set ', ->
			cComponent1 = createMockComponent('test1')
			cComponent2 = createMockComponent()
			nNode = Node [cComponent1, cComponent2]
			entity = mockEntity (comp1 = do cComponent1), (comp2 = do cComponent2)
			nNode.addEntity entity
			expect(nNode.head).to.have.property cComponent1[ symbols.sName ], comp1
			expect(nNode.head).to.have.property cComponent2[ symbols.sName ], comp2

		it 'has @@next property pointing to following node item', ->
			cComponent = createMockComponent()
			nNode = Node [cComponent]
			nNode.addEntity mockEntity( do cComponent )
			nNode.addEntity expected = mockEntity( do cComponent )
			actual = nNode.head[ symbols.sNext ]
			expect(actual).to.be.an "object"
			expect(actual[ symbols.sEntity ]).to.equal expected

		it 'has @@prev property pointing to previous node item', ->
			cComponent = createMockComponent()
			nNode = Node [cComponent]
			nNode.addEntity expected = mockEntity( do cComponent )
			nNode.addEntity mockEntity( do cComponent )
			actual = nNode.tail[ symbols.sPrev ]
			expect(actual).to.be.an "object"
			expect(actual[ symbols.sEntity ]).to.equal expected

		it 'has @@prev and @@next set to null when only single entity added', ->
			cComponent = createMockComponent()
			nNode = Node [cComponent]
			nNode.addEntity mockEntity( do cComponent )
			expect(nNode.head[ symbols.sPrev ]).to.equal null
			expect(nNode.head[ symbols.sNext ]).to.equal null