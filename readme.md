# SCENT: A System-Component-Entity framework

*Make a great game with fresh scent. It smells really good !*

Scent is framework heavily based on the [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters. Thanks to the environments like NodeJS, you can use Scent on the game server too and share most of code.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all of its properties in one big messy object. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Disclaimer

Please note that this is far from complete solution of *how to make the game*. This is only small piece of the whole cake that needs to be used in much more robust environment to handle all game requirements. Possibly it is something that most of games have in common no matter of genre.

## Terminology

Overview of the parts of the framework.

 * The **Component** is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.

 * The **Entity** is any game object. It is composed of components designating the purpose of entity that way.

 * The **Node** is small subset of components owned by single entity and simplifies work of the systems.

 * The **System** is small processor of data contained in components.

 * The **Engine** is meeting place for all mentioned parts.

### Type prefix

There is notation for variables holding known types defined by this framework. Actual variable name is prefixed by single letter denoting the type. First letter of the original variable should be uppercased. We recommend using this notation while using the framework to make clear idea of what is the variable holding.

	cWeapon      component type
	eCharacter   entity instance
	nStructure   node type
	sInput       system initializer
	bName        symbol reference

### No classes

Scent is completely class-less framework. There is no inheritance of any framework part as it's not needed. **Do not use** `new` keyword when using the framework functions. It will not change it's behavior in any way, but internally you will be creating object that is thrown away. For performance reasons there are no checks if you have used `new` keyword.

### EcmaScript 6 support

Framework is using some of the features as defined by EcmaScript6 draft. Since the implementation in current environments are not really production ready, framework is using shims. All used features are exported in `es6-support` file to easily allow replacement by another implementation.

#### Symbol usage

To avoid collisions in some variable names and also to store truly private states, framework is using Symbol structure. All public symbols are accessible from `symbols.coffee` file. You can use these to get required values.

Acknowledged notation exists for the symbols, it uses `@@` as prefix. Anytime when we are using this prefix be aware you have to use the symbol of that name from mentioned file. Note that variable names in the files are conforming to the mentioned notations too.

## How it works

Basically you should define some *components* and add created instances of them to different *entities* while setting required data. Then you can let *systems* do their job with tremendous help of *nodes*. In the end, everything is nicely wrapped in the *engine*.

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's necessary to define component and designate what properties you want to manage in the component.

	cBuilding = Component 'building', ['floors', 'height', 'roofType']

First argument is the name of the component. It helps to identify what are you currently looking at and also to automate some other tasks. The resulting variable `cBuilding` is a **component type** and is used to create component instance that can actually hold the data.

#### Marker component

You can completely omit list of properties and effectively creating component called **marker**. Name for these component should start with some word expressing state, like 'has' or 'is', but it's not enforced in any way.

	cHasRoof = Component 'hasRoof'
	cIsBulletproof = Component 'isBulletproof'

#### Exposed properties

Component type exposes some symbols. You might be interested in @@name to get the actual name of component you have passed in first argument.

There is also property @@number that contains numeric identifier of component type. It is based on prime numbers so it's basically unique if handled correctly.

Lastly there is property @@fields containing array of property names you have requested, filtered out for duplicates and non-string ones.

### Working with components

Once you have component defined, it's very easy to create instance of it and start using it. Let's use the `cBuilding` component from previous example.

	building = cBuilding()
	building.floors = 5
	building.height = 10

Factory function doesn't accepts any parameters. All values have to be set explicitly like shown. You don't need to set all properties and you cannot set properties you haven't defined for the component. Those will be silently ignored and thrown away.

*Note that components are not classes thus avoid using keyword `new` in front of factory function. It doesn't change its behavior, but causes unused object to be created.*

When you are done working with the component and it's not needed anymore, you should call its `@@dispose` method. This will free up any internal resources and destroy values. You should also get rid of any possible references that could hold that component (depends on situation).

	do building[ @@dispose ]
	building = null

### Entity as component collection

Components needs some space to live in. You might also want to tie together more of the different component types to represent particular game **entity**. Entity itself doesn't need any definition or configuration, it's just a container for components.

	entity = Entity()

#### Adding components

That's all that needs to be done. Lets `add` some component in there. Simply pass in the instance of component. You can call `add` method as many times as you want/need.

	entity.add building

Keep in mind, that adding component of the same type replaces existing one inside the entity. In cases where you want to do that, use `replace` method which doesn't produce warning message. It's for the semantics purposes so it's clear from the code, that component is supposed to be replaced.

	entity.replace building

You can also add components in batch during the entity creation. Simply pass them as array in the first argument.

	entityWithComponents = Entity [building, foundation]

#### Retrieving components

For the following methods you need to have access to original factory function of the component as it declares the type of component. First you might want to check if component is part of the entity using `has`. It returns boolean value.

	entityIsBuilding = entity.has cBuilding

To retrieve component object itself you can use `get` method. It will return `null` if component of that type is not present in the entity.

	building = entity.get cBuilding

Avoid calling `has` followed by `get`. For performance purposes use the following approach.

	if building = entity.get cBuilding
		building.floors += 1

#### Removing components

And finally there is `remove` method to unchain the component from the entity. Note that by default the `@@dispose` method of the component will be called upon removal from entity. If you want to prevent that, simply pass the `false` value as the second argument. Use this sparingly to avoid memory leaks.

	entity.remove cBuilding # calls building[ @@dispose ]
	entity.remove cBuilding, false

Methods `add`, `replace` and `remove` returns entity object itself. You can use it to chain the commands if you like.

	entity
		.add building
		.replace foundation
		.remove cWorker

When you don't need whole entity any more, you can remove it from the game simply by calling its `@@dispose` method. All components within entity are disposed as well.

	do entity[ @@dispose ]
	entity = null # Need only if reference is held somewhere

#### Change notifications

Entity object exposes couple of methods monitored with [NoMe](https://github.com/BlackDice/nome). It's highly discouraged to use these methods directly as you would be skipping some of the checks. You can attach to these to get notified about changes. Names of methods are self explanatory.

	Entity.componentAdded
	Entity.componentRemoved
	Entity.disposed

	Entity.componentAdded.notify (component) ->
		# context is entity instance

### Swimming in big entity pool

Since entity is supposed to represent even the tiniest game element, it is expected to have a lot of them. Most of the game logic is driven by some timing mechanism and having to lookup interesting entities to work with every time would be very cumbersome and inefficient. To solve this issue, the framework contains objects called **node**.

Node gives you distinguished list of entities that fulfills set of rules. These rules are based on set of components that entity **must** have to be considered *interesting*. All other entities are just ignored. You can think about this approach like specifying what kind of data has to exists together for you to be able work something out with them.

#### Define the node

All you need to do is to specify set of components you are interested in. That is generally done like this.

	nStructure = Node [cBuilding, cFoundation]

Resulting variable `nStructure` represents **node type**. It manages the internal list of node items that are created and removed automatically based on entities. You will need to keep reference to this variable somewhere otherwise any subsequent call will return new independent node type.

There is more convenient way to store node types. Pass in the memory map at second argument. It will use internal hashing mechanism and identical component set will result in the previously created node type. Order of the components doesn't matter.

	storageMap = new Map
	nStructure1 = Node [cBuilding, cFoundating], storageMap
	nStructure2 = Node [cFoundating, cBuilding], storageMap
	nStructure1 is nStructure2

The best option here is to use instance of Map as defined by ES6 standard, but it can be any object with `get` and `set` methods that behave accordingly to these specs.

#### Node meets entity

There are three methods on the node type object which can be used to notify about entity. Note that when using default engine implementation (more on that later), **this is managed for you** and you don't need to worry about it at all.

	nStructure.addEntity entity
	nStructure.updateEntity entity
	nStructure.removeEntity entity

Generally the `updateEntity` is the smartest one and is able to decide if entity needs to be added, removed or just updated. However it's more costly in performance. If you know exactly what needs to be done, use one of remaining appropriate methods.

Passed entity object is evaluated for current components and if all of them are present, node item is made (or updated/removed). You are not getting any feedback at this point (except errors for invalid entity). Instead the internal list is updated and you can access that as a whole later.

#### Accessing nodes

In most of the scenarios you are interested in the whole list of node items and you want iterate through them.

	loopNodes = (node, idx) ->
		# Do something with the node
	
	nStructure.each loopNodes

##### Advanced looping

Internally the list of node items is held in linked list structure. In case you need more control over the looping, continue reading. 

You have access to the beginning and also end of the list.

	nStructure.head # first node item in the list
	nStructure.tail # last node item in the list

Every node item has properties `@@next` and `@@prev` to reference its neighbors  from the list. This allows you to make loops like this.

	node = nStructure.head
	while (node)
		# Do something with the node
		node = node[ @@next ]

Note that `@@next` and `@@prev` properties are `null` in case they would be pointing to itself. Eg. one node in the list has no *next*, first node of two item list has no *prev*, etc... 

#### Access to components

Node item is directly linked to entity that is stored into `@@entity` property. You can access components as usual. Luckily for the convenience the node item contains components directly. Names of components are used here to define property names for easy access.

	loopNodes = (node) ->
		node.building.floors += 1 # directly increase floors of cBuilding component
		if node.foundation.material = 'steel' 
			do node[ @@entity ][ @@dispose ] # remove the entity from the game

### Need for logic

Entity itself is a nice package of related data, but it doesn't really do anything. For that purpose we need another piece of the puzzle - **systems** (note the plural). 

System is piece of code that is able to work with data. System can be really simple, like single function that does its job when asked for it. Over complicated system is much harder to read, test, maintain and debug. Keep that in mind when designing your systems.

#### Defining the system

System alone is just empty shell waiting to be filled with code that does its work on components through node types. System is required to have name which purpose as for now is mainly for easier debugging. It's only checked for duplicity.

	sWorker = System 'worker', ->

Resulting variable `sWorker` is equal to the passed function from the second argument. Additionally it stores the system name in `@@name` variable. Lets mark the returned function as **system initializer**. It's role is simply to initialize system logic upon invocation. Basically you could have system like the following code.

	System 'worker', ->

		components = require './components'
		nStructure = Node [components.cBuilding, components.cFoundation]
		nStructure.each loopNode

	loopNode = (node) ->
		# Worker can "build" the structure by adding more components to entity

This is completely viable approach, but it presents itself with some challenges. For starters you would be getting only local node type without memory map passed along. You would have to watch for entities added or changed by other systems. You can have just single system of course and do everything in it, but in that case Scent is not for you.

Lets do it other way for once. It's time to meet the **engine**.

### Engine

Engine is here to help with any heavy lifting. Basic engine keeps list of entities, tells about them to created node types and it can manage systems for you. However stay tuned because this is highly extensible and you can easily choose what functionality should your engine support or even add your own!

#### Create the engine

The most simplest way to create engine instance is like this. This will provide you with the basic functionality as it will be explained below.

	engine = Engine()

Note that engine instance is frozen (with `Object.freeze`) thus you cannot do any changes to it. This is simply security policy. Later you will learn how to actually extend it in very easy way.

#### Update cycle

Usually you want your systems to their work in some kind of timed fashion. How you actually setup your timing mechanism is entirely up to you. Engine only provides `update` method that loops through update handles registered by your systems.

	engine.update timestamp

You can pass any arguments you like in there. Those will be simply handed over to update handlers. To register update handler you can do this (even repeatedly) from within system initializer.

	engine.onUpdate (timestamp) ->

#### Access to nodes

Engine handles memory map of node types for you. All node types you access through the engine are remembered and you can access them from any system.

	nStructure = engine.getNodeType [cBuilding, cFoundation]

#### Entity management

Engine keeps the list of all entities for you. It also automatically informs created node types about these. All you need to do is call method `addEntity`.

	eCorporateBuilding = engine.addEntity [
		building = do cBuilding
		foundation = do cFoundation
	]
	building.floors = 10
	foundation.material = 'stone'

When you call `@@dispose` method of entity instance, it will be removed from engine and relevant nodes as well.

Keep in mind that entity is not added to nodes right away. Such changes are queued up and will be processed at the end of update cycle. This is to ensure consistent state of available nodes.

#### Add the systems

System initializers are added to engine first. These are not invoked till the engine is actually started.

	engine.addSystem sInput

Above method supports only single system passed in. You have to call it for each system separately. For the sake of simplicity, there is also `addSystems` method which expects array of system initializers.

	engine.addSystems [sInput, sDisply, sMovement]

#### Start the engine

Now when your engine is pumped up with systems, you can start it. It will call all system initializer functions to let them do their setup. There is currently no way how to actually stop the engine itself, but you can simply stop invoking update cycles if necessary. However you can call its `@@dispose` method to clean all used resources if you ever need that.

	engine.start done

Argument `done` is here to support asynchronous operations. When everything is loaded and ready, it will be called in error-first callback style. System can be made asynchronous using an injections.

#### Injections for system

You may have heard about term *dependency injection*. It's rather simple but powerful idea. Scent engine provides this to power up systems more easily. As you may have noticed earlier, system initializer function isn't initially expecting any arguments. Since each system is different and has different needs, it would be cumbersome to have fixed arguments in there.

	System 'powerful', (engine) ->

Engine will analyze the name of arguments you have used for function declaration and provide configured values upon its invocation. Order of the arguments or their number doesn't matter here.

There are two injections that are provided for you by default. First can be seen in example above, it's engine instance.

##### Asynchronous system

Second built-in injection is named `done` and once used in system initializer arguments, it marks the system as *asynchronous*. It is expected from you to call this callback whenever the system is ready.

	System 'async', (done) ->
		makeAsyncCall(done)

Callback is error-first style and in case you pass anything truthy there, it will interrupt engine start and the result is propagated to callback from `start` method. Any arguments beside first one are ignored (at least for now). 

Please note that once the engine is started, adding asynchronous system doesn't propagate its *done* state anywhere. You would have to ensure this on your own. Thus we recommend adding all asynchronous systems before engine is started.

#### Extensible engine

Now it's time to go deeper as so far the engine is nice, but not that powerful as it can be. There are numerous extensions available and you can write your own too. Extension is simple function that is called by engine during its initialization. When that happens ? Look at the following code.

	engine = Engine (engine) ->
		# Here goes any extensions and setup

Passed function is called immediately with created engine instance except it is not frozen yet in here. You can do anything you like with the engine instance. Once this function ends, engine instance is frozen and cannot be extended further.

Return value of engine initialization function is not important, but if you return array, it is assumed to be list of system initializers and it is handed over to `addSystems` method.

##### Custom injections

During engine initialization you can call `provide` function passed in arguments to actually setup your own injection for system initializers.

	engine = Engine (engine, provide) ->
		provide 'app', appInstance

Name defined here corresponds to the name of argument you need to use in your system initializer function. You can specify any static value that you want to provide, eg. object with shared settings that some systems might need. 

If you specify function, it will be called every time when some system asks for such injection. You are expected to return some value that will be actually injected into the system.

	setupFunction = (engine, systemInitializer) ->
		# Returned value is passed to system initializer
		return getConfigForSystem systemInitializer[ @@name ]
	
	engine = Engine (engine, provide) ->
		provide 'setup', setupFunction

	engine.addSystem System 'withSetup', (setup) ->
		# Your system specific config is ready in here

#### Multiple engines?

Technically you can created multiple engine instances, but there is currently no way how to add created entity to the engine. All entities and node types are private to that engine. This is the current limitation of the implementation. If the need for multiple engines arises in future, we might implement it.
