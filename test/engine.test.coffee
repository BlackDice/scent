{Scent, expect, sinon, resetComponentIdentities, mockSystem} = require './setup'
{Engine, Entity, Component, Symbols} = Scent
wu = require 'wu'

NoMe = require 'nome'
Lill = require 'lill'

describe 'Engine', ->

    beforeEach ->
        resetComponentIdentities()
        @cAlphaComponent = Component 'alpha'
        @cBetaComponent = Component 'beta'
        @cGamaComponent = Component 'gama'

    it 'should be a function', ->
        expect(Engine).to.be.a "function"

    it 'expects optional function initializer at first argument', ->
        toThrow = (msg, fn) ->
            expect(fn).to.throw TypeError, /expected function/, msg
        toThrow 'string', -> Engine 'str'
        toThrow 'number', -> Engine 1
        toThrow 'bool', -> Engine true
        toThrow 'false', -> Engine false
        toThrow 'array', -> Engine []
        toThrow 'object', -> Engine {}

    it 'returns engine instance', ->
        actual = Engine()
        expect(actual).to.be.an "object"
        expect(actual).to.be.an.instanceof Engine

    it 'invokes function passed in first argument with extensible engine instance', ->
        engine = Engine (spy = sinon.spy())
        expect(spy).to.have.been
            .calledOnce
            .calledWith(engine)
        Engine (engine2) ->
            expect(Object.isExtensible engine2).to.be.true
            do engine[ Symbols.bDispose ]
            do engine2[ Symbols.bDispose ]

    afterEach ->
        do @engine?[ Symbols.bDispose ]

    it 'instance passes the `instanceof`', ->
        expect(Engine()).to.be.an.instanceof Engine

    it 'passes `Engine.prototype.isPrototypeOf` check', ->
        expect(Engine.prototype.isPrototypeOf Engine()).to.be.true

    describe 'instance.registerComponent()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'registerComponent'

        it 'expects valid component type', ->
            test = @engine.registerComponent.bind @engine
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expected component type/, msg
            toThrow 'string', -> test 'str'
            toThrow 'number', -> test 1
            toThrow 'bool', -> test true
            toThrow 'false', -> test false
            toThrow 'array', -> test []
            toThrow 'object', -> test {}

        it 'ignores component type with already registered name', ->
            @engine.registerComponent @cAlphaComponent
            @engine.registerComponent new Component('alpha')
            expect(@engine.accessComponent 'alpha').to.equal @cAlphaComponent

        it 'uses second argument as component type identification instead of type name', ->
            @engine.registerComponent @cAlphaComponent, 'test'
            @engine.registerComponent @cBetaComponent, bTest = Symbol()
            expect(@engine.accessComponent 'test').to.equal @cAlphaComponent
            expect(@engine.accessComponent bTest).to.equal @cBetaComponent

    describe 'instance.accessComponent()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'accessComponent'

        it 'retrieves component registered by registerComponent method', ->
            @engine.registerComponent @cAlphaComponent
            @engine.registerComponent @cBetaComponent
            expect(@engine.accessComponent 'alpha').to.equal @cAlphaComponent
            expect(@engine.accessComponent 'beta').to.equal @cBetaComponent

    describe 'instance.createComponent()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'createComponent'

        it 'creates component instances registered by registerComponent method', ->
            @engine.registerComponent @cAlphaComponent
            @engine.registerComponent @cBetaComponent
            expect(@engine.createComponent 'alpha').to.be.an.instanceOf @cAlphaComponent
            expect(@engine.createComponent 'beta').to.be.an.instanceOf @cBetaComponent

    describe 'instance.getNodeType()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'getNodeType'

        it 'should return node type for each component set', ->
            nTest1 = @engine.getNodeType [@cAlphaComponent, @cBetaComponent]
            nTest2 = @engine.getNodeType [@cBetaComponent, @cAlphaComponent]
            nTest3 = @engine.getNodeType [@cAlphaComponent]

            expect(nTest1).to.be.an 'object'
            expect(nTest1).to.respondTo 'each'
            expect(nTest1).to.respondTo 'updateEntity'
            expect(nTest1).to.respondTo 'onRemoved'

            expect(nTest1).to.equal nTest2
            expect(nTest1).to.not.equal nTest3

        it 'should fill node type with existing entities', ->
            firstEntity = @engine.buildEntity [
                new @cAlphaComponent
                new @cGamaComponent
            ]
            secondEntity = @engine.buildEntity [
                new @cAlphaComponent
                new @cBetaComponent
            ]
            nTest = @engine.getNodeType [@cAlphaComponent]
            expect(nTest.size).to.equal 2
            expect(nTest.head[ Symbols.bEntity ]).to.equal firstEntity

        it 'should pass registered component to node type', ->
            @engine.registerComponent @cAlphaComponent
            nNode = @engine.getNodeType ['alpha']
            expect(nNode.types[0]).to.equal @cAlphaComponent

    describe 'instance.addEntity()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'addEntity'

        it 'should accept existing entity', ->
            alpha = new @cAlphaComponent
            beta = new @cBetaComponent
            entity = new Entity [alpha, beta]
            @engine.addEntity entity

            expect(wu(@engine).has(entity)).to.be.true
            entity.dispose()

        it 'should return same entity', ->
            alpha = new @cAlphaComponent
            beta = new @cBetaComponent
            entity = new Entity [alpha, beta]
            entity2 = @engine.addEntity entity

            expect(entity).to.equal entity2
            entity.dispose()
            entity2.dispose()

    describe 'instance.buildEntity()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'buildEntity'

        it 'should return new entity instance', ->
            expect(entity = @engine.buildEntity()).to.be.an "object"
            expect(entity).to.respondTo 'add'
            expect(entity).to.respondTo 'has'
            expect(entity).to.respondTo 'get'
            expect(entity2 = @engine.buildEntity()).to.not.equal entity
            entity.dispose()
            entity2.dispose()

        it 'should return entity with components added', ->
            alpha = new @cAlphaComponent
            beta = new @cBetaComponent
            entity = @engine.buildEntity [alpha, beta]

            expect(entity.size).to.equal 2
            expect(entity.has @cAlphaComponent).to.be.true
            expect(entity.get @cBetaComponent).to.equal beta
            entity.dispose()

        it 'uses registered components when creating an entity', ->
            @engine.registerComponent @cAlphaComponent
            @engine.registerComponent @cBetaComponent
            entity = @engine.addEntity ['alpha']
            entity.add 'beta'
            entity.replace 'alpha'
            expect(entity.get('alpha')).to.be.an.instanceOf @cAlphaComponent
            expect(entity.has('beta')).to.be.true
            entity.remove 'beta'
            expect(entity.has('beta')).to.be.false

    describe 'instance[@@iterator]', ->

        beforeEach ->
            @engine = new Engine()
            @entity1 = @engine.buildEntity();
            @entity2 = @engine.buildEntity();
            @entity3 = @engine.buildEntity();

        it 'should be an iterator function', ->
            expect(@engine[Symbol.iterator]).to.be.a 'function'
            iterator = do @engine[Symbol.iterator]
            expect(iterator).to.have.a.property 'next'

        it 'allows to iterate over existing entities', ->
            actual = []
            wu(@engine).forEach((ent) -> actual.push(ent));
            expect(actual).to.eql([
                @entity1
                @entity2
                @entity3
            ]);

    describe 'instance.addSystem()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'addSystem'

        it 'expects function at first argument', ->
            engine = @engine
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expected function/, msg
            toThrow 'string', -> engine.addSystem 'str'
            toThrow 'number', -> engine.addSystem 1
            toThrow 'bool', -> engine.addSystem true
            toThrow 'false', -> engine.addSystem false
            toThrow 'array', -> engine.addSystem []
            toThrow 'object', -> engine.addSystem {}

        it 'forbids to add same system initializer multiple times', ->
            system = mockSystem('again')
            @engine.addSystem system
            expect(=> @engine.addSystem system).to.throw Error, /already added/

        it 'returns engine instance itself', ->
            expect(@engine.addSystem mockSystem()).to.equal @engine

        it 'invokes function when engine is already started', ->
            @engine.start()
            systemAfter = mockSystem('after')
            @engine.addSystem systemAfter
            expect(systemAfter).to.have.been.calledOnce

    describe 'instance.addSystems()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'addSystems'

        it 'expects array of system initializers at first argument', ->
            engine = @engine
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expected array/, msg
            toThrow 'void', -> engine.addSystems()
            toThrow 'null', -> engine.addSystems null
            toThrow 'string', -> engine.addSystems 'str'
            toThrow 'number', -> engine.addSystems 1
            toThrow 'bool', -> engine.addSystems true
            toThrow 'object', -> engine.addSystems {}
            toThrow 'function', -> engine.addSystems new Function

        it 'returns engine instance itself', ->
            expect(@engine.addSystems [mockSystem()]).to.equal @engine

    describe 'instance.start()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'start'

        it 'should invoke added system initializers', ->
            system1 = mockSystem('first')
            system2 = mockSystem('second')
            @engine.addSystems [system1, system2]
            @engine.start()
            expect(system1).to.have.been.calledOnce
            expect(system2).to.have.been.calledOnce

        it 'expects optional callback at first argument', ->
            start = @engine.start
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expected callback/, msg
            toThrow 'string', -> start 'str'
            toThrow 'number', -> start 1
            toThrow 'bool', -> start true
            toThrow 'false', -> start false
            toThrow 'array', -> start []
            toThrow 'object', -> start {}

        it 'fails when called more than once', ->
            @engine.start()
            expect(=> @engine.start()).to.throw Error, /has been started/

        it 'propagates error during system initialization', ->
            @engine.addSystem mockSystem 'failing', ->
                throw 'it is failure'
            expect(=> @engine.start()).to.throw Error, /it is failure/

        it 'provides engine instance to system initializer', ->
            system = mockSystem 'withEngine', ($engine) =>
                expect($engine).to.equal @engine
            @engine.addSystem system
            @engine.start()

        it 'invokes callback when async systems are initialized', (done) ->
            called = no
            @engine.addSystem mockSystem 'async', ($done) ->
                setTimeout (-> called = yes; $done()), 0
            @engine.start ->
                expect(called).to.be.true
                done()

        it 'invokes callback when no async systems are present', (done) ->
            @engine.addSystem mockSystem()
            @engine.start -> done()

        it 'invokes callback with error during system initialization', ->
            @engine.addSystem mockSystem 'failing', ->
                throw 'it is failure'
            spy = sinon.spy()
            @engine.start spy
            expect(spy).to.have.been.calledOnce
            expect(spy.firstCall.args[0]).to.be.an.instanceof Error
            expect(spy.firstCall.args[0].message).to.match /it is failure/

        it 'invokes callback with error during async system initialization', ->
            @engine.addSystem mockSystem 'failing', ($done) ->
                $done new Error 'it is failure'
            spy = sinon.spy()
            @engine.start spy
            expect(spy).to.have.been.calledOnce
            expect(spy.firstCall.args[0]).to.be.an.instanceof Error
            expect(spy.firstCall.args[0].message).to.match /it is failure/

    describe 'instance.update()', ->

        beforeEach ->
            @engine = Engine()
            @engine.start()
            @nAlphaNode = @engine.getNodeType [@cAlphaComponent]
            @nBetaNode = @engine.getNodeType [@cBetaComponent]
            @nGamaNode = @engine.getNodeType [@cGamaComponent]
            @eTestEntity = @engine.buildEntity [new @cAlphaComponent, new @cBetaComponent]

        afterEach ->
            @eTestEntity.dispose()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'update'

        it 'cannot be invoked till engine is started', ->
            engine = new Engine
            expect(engine.update.bind(engine)).to.throw Error, /needs to be started/

        it 'adds created entity to compatible nodes', ->
            expect(@nAlphaNode.size).to.equal 0
            expect(@nBetaNode.size).to.equal 0
            @engine.update()
            expect(@nAlphaNode.size).to.equal 1
            expect(@nBetaNode.size).to.equal 1

        it 'removes disposed entity from nodes', ->
            @engine.update()
            @eTestEntity.dispose()
            expect(@nAlphaNode.size).to.equal 1, 'alpha before update'
            expect(@nBetaNode.size).to.equal 1, 'beta before update'
            @engine.update()
            expect(@nAlphaNode.size).to.equal 0, 'alpha after update'
            expect(@nBetaNode.size).to.equal 0, 'alpha after update'

        it 'removes incompatible entity from nodes', ->
            @engine.update()
            @eTestEntity.remove @cAlphaComponent
            expect(@nAlphaNode.size).to.equal 1, 'before update'
            @engine.update()
            expect(@nAlphaNode.size).to.equal 0, 'after update'

        it 'invokes action type finish() method to clear action list', ->
            @engine.onAction 'test1', spy1 = sinon.spy()
            @engine.onAction 'test2', spy2 = sinon.spy()
            @engine.triggerAction 'test1'
            @engine.triggerAction 'test2'
            @engine.update()
            expect(spy1).to.have.been.calledOnce
            expect(spy2).to.have.been.calledOnce

        it 'allows to modify entity in Node.onAdded handler', (done) ->
            @nAlphaNode.onAdded =>
                @eTestEntity.remove(@cBetaComponent)
            @nBetaNode.onRemoved -> done()
            @engine.update()

        it 'processes actions that was triggered during another action', ->
            spyFirst = sinon.spy()
            spySecond = sinon.spy()
            spyThird = sinon.spy()
            @engine.onAction 'third', =>
                # This action should be postponed to next update
                # otherwise it would cause endless loop
                @engine.triggerAction 'first'
                spyThird()
            @engine.onAction 'first', =>
                @engine.triggerAction 'second'
                spyFirst()
            @engine.onAction 'second', =>
                @engine.triggerAction 'third'
                spySecond()
            @engine.triggerAction 'first'

            @engine.update()
            expect(spyFirst).to.have.been.calledOnce
            expect(spySecond).to.have.been.calledOnce
            expect(spyThird).to.have.been.calledOnce

            @engine.update()
            expect(spyFirst).to.have.been.calledTwice

    describe 'instance.onUpdate', ->

        beforeEach ->
            @engine = Engine()
            @engine.start()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'onUpdate'

        it 'expects callback function', ->
            {onUpdate} = @engine
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expects function/, msg
            toThrow 'string', -> onUpdate 'str'
            toThrow 'number', -> onUpdate 1
            toThrow 'bool', -> onUpdate true
            toThrow 'false', -> onUpdate false
            toThrow 'array', -> onUpdate []
            toThrow 'object', -> onUpdate {}

        it 'invokes passed callback when engine.update is invoked', ->
            @engine.onUpdate(spy = sinon.spy())
            @engine.update(10, 20)
            expect(spy).to.have.been.calledOnce.calledWith(10, 20).calledOn @engine

    describe 'instance.triggerAction()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'triggerAction'

        it 'returns engine instance itself', ->
            actual = @engine.triggerAction 'test'
            expect(actual).to.equal @engine

        it 'triggers action for specified action name', (done) ->
            @engine.onAction 'test', -> # just to allow action trigger
            @engine.triggerAction 'test', 20
            actionType = @engine.getActionType 'test'
            actionType.each (action) ->
                expect(action.data).to.equal 20
                done()

    describe 'instance.onAction', ->

        beforeEach ->
            @engine = Engine()
            @engine.start()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'onAction'

        it 'expects action name in first argument', ->
            {onAction} = @engine
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expected name/, msg
            toThrow 'number', -> onAction 1
            toThrow 'bool', -> onAction true
            toThrow 'false', -> onAction false
            toThrow 'array', -> onAction []
            toThrow 'object', -> onAction {}
            toThrow 'function', -> onAction new Function

        it 'expects callback function in second argument', ->
            onAction = @engine.onAction.bind @engine, 'test'
            toThrow = (msg, fn) ->
                expect(fn).to.throw TypeError, /expected callback/, msg
            toThrow 'string', -> onAction 'str'
            toThrow 'number', -> onAction 1
            toThrow 'bool', -> onAction true
            toThrow 'false', -> onAction false
            toThrow 'array', -> onAction []
            toThrow 'object', -> onAction {}

        it 'returns engine instance', ->
            expect(@engine.onAction('name', ->)).to.equal @engine

        it 'invokes callback for each triggered action when update is called', ->

            data = alpha: true, beta: false
            meta = alpha: false, beta: true

            spy = sinon.spy()
            expected = -> i = 0; return (action) ->
                spy arguments...
                if i is 0
                    expect(action.data).to.equal data
                else if i is 1
                    expect(action.meta).to.equal meta
                i++

            @engine.onAction 'test', expected()
            @engine.onAction 'test', expected()
            @engine.triggerAction 'test', data
            @engine.triggerAction 'test', null, meta
            @engine.getActionType 'not processed'
            @engine.update()
            expect(spy.callCount).to.equal 4

    describe 'instance.size', ->

        beforeEach ->
            @engine = Engine()

        it 'is read-only property equal to 0 for empty engine', ->
            expect(@engine).to.have.property "size"
            expect(=> @engine.size = 500).to.throw
            expect(@engine.size).to.equal 0

        it 'returns number of entities in engine', ->
            @engine.buildEntity() for i in [1..10]
            expect(@engine.size).to.equal 10


    describe 'provide()', ->

        it 'is function passed as second argument in engine initializer', ->
            Engine (engine, provide) ->
                expect(provide).to.be.a "function"

        it 'cannot be called once engine initialization is over', ->
            Engine (engine, @provide) =>
            expect(=> @provide()).to.throw Error, /initialized engine/

        it 'expects name of injection in first argument', ->
            toThrow = (msg, value) ->
                Engine (engine, provide) ->
                    expect(-> provide value).to.throw TypeError, /expected injection name/, msg
            toThrow 'empty string', ''
            toThrow 'number', 1
            toThrow 'bool', true
            toThrow 'false', false
            toThrow 'array', []
            toThrow 'object', {}
            toThrow 'function', ->

        it 'expects non-null value in second argument', ->
            toThrow = (msg, value) ->
                Engine (engine, provide) ->
                    expect(-> provide 'test', value).to.throw TypeError, /non-null value/, msg
            toThrow 'void'
            toThrow 'null', null

        it 'forbids to override injection with same name', ->
            Engine (engine, provide) ->
                provide 'test', 0
                expect(-> provide 'test', false).to.throw TypeError, /already defined/

        it 'returns undefined', ->
            Engine (engine, provide) ->
                expect(provide 'test', '').to.equal undefined

        it 'injects value to system initializer for named argument', ->
            engine = Engine (engine, provide) ->
                provide 'bool', false
                provide 'num', 10
                provide 'str', 'string'
                provide 'obj', {someObject: yes}

            system = mockSystem 'injected', (bool, str, obj, num, nothing) ->
                expect(bool).to.be.false
                expect(str).to.equal 'string'
                expect(obj).to.eql {someObject: yes}
                expect(num).to.equal 10
                expect(nothing).to.equal null

            engine.addSystem system
            engine.start()

        it 'invokes function injection before passing to system initializer', ->
            spy = sinon.spy()
            engine = Engine (engine, provide) ->
                provide 'fn', spy
            engine.addSystem system = mockSystem 'injection', (fn) ->
            engine.start()
            expect(spy).to.have.been.calledOnce.calledWithExactly engine, system

        it 'injects values returned from injection function', ->
            engine = Engine (engine, provide) ->
                provide 'dyn', (engine, systemInitializer) ->
                    return systemInitializer[ Symbols.bName ]
            engine.addSystem mockSystem 'expected', (dyn) ->
                expect(dyn).to.equal 'expected'
            engine.start()
