{expect, sinon, createMockComponent, mockSystem} = require './setup'
Engine = require '../src/engine'
symbols = require '../src/symbols'

describe 'Engine', ->

    before ->
        @cAlphaComponent = createMockComponent('alpha')
        @cBetaComponent = createMockComponent('beta')
        @cGamaComponent = createMockComponent('gama')

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

    it 'returns engine instance as frozen object', ->
        actual = Engine()
        expect(actual).to.be.an "object"
        expect(Object.isFrozen actual).to.be.true

    it 'invokes function passed in first argument with extensible engine instance', ->
        engine = Engine spy = sinon.spy()
        expect(spy).to.have.been
            .calledOnce
            .calledOn(null)
            .calledWith(engine)
        Engine (engine2) ->
            expect(Object.isExtensible engine2).to.be.true

    describe 'instance.getNode()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'getNode'

        it 'should return node type for each component set', ->
            nTest1 = @engine.getNode [@cAlphaComponent, @cBetaComponent]
            nTest2 = @engine.getNode [@cBetaComponent, @cAlphaComponent]
            nTest3 = @engine.getNode [@cAlphaComponent]

            expect(nTest1).to.be.an 'object'
            expect(nTest1).to.respondTo 'each'
            expect(nTest1).to.respondTo 'updateEntity'

            expect(nTest1).to.equal nTest2
            expect(nTest1).to.not.equal nTest3

    describe 'instance.addEntity()', ->

        beforeEach ->
            @engine = Engine()

        it 'should be a function', ->
            expect(@engine).to.respondTo 'addEntity'

        it 'should return new entity instance', ->
            expect(entity = @engine.addEntity()).to.be.an "object"
            expect(entity).to.respondTo 'add'
            expect(entity).to.respondTo 'has'
            expect(entity).to.respondTo 'get'
            expect(@engine.addEntity()).to.not.equal entity

        it 'should return entity with components added', ->
            alpha = do @cAlphaComponent
            beta = do @cBetaComponent
            beta2 = do @cBetaComponent
            entity = @engine.addEntity [alpha, beta, beta2]

            expect(entity.size).to.equal 2
            expect(entity.has @cAlphaComponent).to.be.true
            expect(entity.get @cBetaComponent).to.equal beta2

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

        it 'expects function to have @@name', ->
            expect(=> @engine.addSystem(->)).to.throw TypeError, /not system initializer/

        it 'expects @@name of system to be unique', ->
            @engine.addSystem mockSystem()
            expect(=> @engine.addSystem mockSystem()).to.throw TypeError, /has to be unique/

        it 'returns engine instance itself', ->
            expect(@engine.addSystem mockSystem()).to.equal @engine

        it 'forbids to add same system initializer multiple times', ->
            system = mockSystem('again')
            @engine.addSystem system
            expect(=> @engine.addSystem system).to.throw Error, /already added/

        it 'invokes function only if engine is already started', ->
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
            system = mockSystem 'withEngine', (engine) =>
                expect(engine).to.equal @engine
            @engine.addSystem system
            @engine.start()

        it 'invokes callback when async systems are initialized', (done) ->
            called = no
            @engine.addSystem mockSystem 'async', (done) ->
                setTimeout (-> called = yes; done null), 0
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
            @engine.addSystem mockSystem 'failing', (done) ->
                done new Error 'it is failure'
            spy = sinon.spy()
            @engine.start spy
            expect(spy).to.have.been.calledOnce
            expect(spy.firstCall.args[0]).to.be.an.instanceof Error
            expect(spy.firstCall.args[0].message).to.match /it is failure/

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
                    return systemInitializer[ symbols.bName ]
            engine.addSystem mockSystem 'expected', (dyn) ->
                expect(dyn).to.equal 'expected'
            engine.start()