# SCENT: A System-Component-Entity framework

*Make a great game with fresh scent. It smells really good !*

Scent is framework heavily based on the [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters. Thanks to the environments like NodeJS, you can use Scent on the game server too and share most of code.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all of its properties in one big messy object. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Disclaimer

Please note that this is far from complete solution of *how to make the game*. This is only small piece of the whole cake that needs to be used in much more robust environment to handle all game requirements. Possibly it is something that most of games have in common no matter of genre.

### In development

Framework is being actively used in development of our game. It will be improved and changed over time as need arise. Check out the [contributing file](contributing.md) if you want to help with something.

There is no Roadmap for the framework yet, it mostly depends on ours needs in the game. One essential feature is still missing compared to Ash - Finite State Machine. This will be implemented for sure in relatively short time frame.

## Installation and basic usage

Framework is available from NPM (`npm install -S scent`) and Bower (`bower install -S scent`). Simply run any of these and you are set to go.

We are using CommonJS modules. You can use these in NodeJS and also in browser with the help of Browserify. To access any parts of framework simply make call like the following.

	{Component, Entity, Node, System, Engine, Symbols} = require 'scent'

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
	bName        symbol reference

### No classes

Scent is completely class-less framework. There is no inheritance of any framework part. **Do not use** `new` keyword when using the framework functions. It will not change it's behavior in any way, but internally you will be creating object that is thrown away. For performance reasons there are no checks if you have used `new` keyword.

### Error handling

There are some checks for correct type or format of arguments that can throw error. Basically you don't need to handle these errors because they are meant to alert you about doing something seriously wrong mostly in the setup phase.

There is minimum of runtime errors (except unexpected ones). Instead the [debug](https://www.npmjs.org/package/debug) module is used with prefix of "scent:" that warns you about runtime issues.

### EcmaScript 6 support

Framework is using some of the features as defined by EcmaScript 6 draft. Since the implementation in current environments are not really production ready, we are using shims. All used features are exported in `src/es6-support` file to easily allow replacement by another shim implementation if needed.

#### Symbol usage

To avoid collisions in some variable names and also to store truly private states, framework is using the **Symbol** structure. All public symbols are accessible from Symbols exported variable of Scent entry point (see above).

Acknowledged notation exists for the symbols, it uses `@@` as prefix. Anytime when we are using this prefix be aware you have to use the symbol of that name from mentioned file.

## How it works

Basically you should define some *component types*, created instances of them, set data and add them to different *entities*. Then you can let *systems* do their job with tremendous help of *nodes*. In the end, everything is nicely wrapped by the *engine*.

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some **place to store data**. That's the role of the component. However before you can store some data in there, it's necessary to define component type and designate what properties you want to manage in there.

	cBuilding = Component 'building', 'floors height roofType'

 * First argument is the name of the component. It helps to identify what are you currently looking at and also to automate some other tasks (see Node below).

 * Second argument is optional and contains list of properties you want to define for a component type.

   - Property name has to start with letter and be composed of alphanumeric characters only.
   - Properties with non-alphanumeric characters are completely omitted.
   - Any whitespace characters are used as delimiter.
   - Duplicates are automatically removed.

The resulting variable `cBuilding` is a **component type** and by invoking it you can create component instance that can actually hold the data. You might also need this type to do some checks (eg. entity methods, see below).

#### Save component type

Created component type is **not stored anywhere**. Upon invoking the function with same component name you would be getting different object. This is merely to prevent the *global* behavior of the Component avoiding some unwanted issues in more complex game systems.

#### Marker component

You can completely omit list of properties and effectively create component type called **marker**. Name for marker components should start with some word expressing state, like 'has' or 'is', but it's not enforced in any way.

	cHasRoof = Component 'hasRoof'
	cIsBulletproof = Component 'isBulletproof'

#### Identity number

Each component type is assigned identity number upon creation. It is mainly used to easily identify group of component types (eg. by Node). You can also use it for some kind of storage mechanism since name of component type doesn't need to be unique.

Identity number is retrieved from internal list of prime numbers, currently ending at number 7919. That's exactly 1000 component types available to use. If there is ever need for more component types, we might consider some more robust solution. For now this is pre-generated list for performance reasons.

The list is global, so any subsequent calls to Component function will grab the next number from the list and block it for that component type.

##### Overwriting identity

For more complex architecture you might want to need specify identity of component type by yourself. If you try to pass in number that is already taken or not present in the internal list, error will be thrown.

	cPerson = 'person', '#677 head torso limbs'
	cPerson[ Symbols.bIdentity ] === 677

Simply prefix your identity number with `#`. It can be anywhere in properties list. You can specify only single identity. First occurrence of the pattern is taken into account, any subsequent is ignored.

#### Exposed properties

Component type exposes some properties using symbols.

 * *@@name* is actual name of component you have passed in first argument.
 * *@@fields* is array of parsed property names from the second argument filtered out for duplicates. You cannot change component definition by changing this.
 * *@@identity* contains numeric identifier of component type based on prime numbers (see above).
 * *@@changed* is timestamp (from `Date.now()` call) of the last change in component data. If no change occurred, there will be 0.

#### Working with components

Once you have component defined, it's very easy to create instance of it and start using it. Let's use the `cBuilding` component from previous example.

	building = cBuilding()
	building.floors = 5
	building.height = 10

Data in the component should be set explicitly like shown. You don't need to set all properties and you cannot set properties you haven't defined for the component type. Those will be silently ignored and thrown away.

There is another supported way of defining data for a component. This is intended for serialization mechanics more than general usage as it is quite confusing to read and you can easily make a mistake. Following gives the same result as above example.

	building = cBuilding [5, 10]

Note that passed array is kept for the further usage. Be warned that keeping reference to it may cause unexpected issues. If you want to keep around those data, you better make a clone from it.

#### Dispose component

When you are done working with the component and it's not needed anymore, you should call its `@@dispose` method. This will free up any internal resources and destroy values.

	do building[ @@dispose ]
	building = null

Disposed component is stored in internal pool and will be used again when component of the same type is created again. For that reason you should not hold component reference anywhere if you plan to dispose it later.

#### Validating types

This might come in handy in some runtime situations, but it's probably more useful in unit tests. Take this feature as experimental. It can be removed in future if we decide that its cost overweights its usefulness.

	(cBuilding instanceOf Component) is true
	(Component.prototype.isPrototypeOf cBuilding) is true

	(building instanceOf cBuilding) is true
	(cBuilding.prototype.isPrototypeOf building) is true

### Entity as component collection

Components needs some space to live in. You might also want to tie together more of the different component types to represent particular game **entity**. Entity itself doesn't need any definition or configuration, it's just a container for components.

	entity = Entity()

#### Adding components

Entity without components is just empty meaningless shell. Lets `add` some component in there. Simply pass in the instance of component. You can call `add` method as many times as you want.

	entity.add building

Keep in mind, that adding component of the same type **replaces existing one** inside the entity. In cases where you want to do that, use `replace` method which doesn't produce warning message. It's for the semantics purposes so it's clear from the code, that component is supposed to be replaced.

	entity.replace building

You can also add components in batch during the entity creation. Simply pass them as array in the first argument.

	entityWithComponents = Entity [building, foundation]

#### Retrieving components

For the following methods you need to have access to component type as it declares the type of component. First you might want to check if component is part of the entity using `has`. It returns boolean value.

	entityIsBuilding = entity.has cBuilding

To retrieve component instance itself you can use `get` method. It will return `null` if component of that type is not present in the entity.

	building = entity.get cBuilding

In case you want to retrieve whole list of component instances, use `getAll` method.

	components = entity.getAll()

#### Removing components

Call `remove` method to unchain the component instance from entity.

	entity.remove cBuilding

If you don't have component type at your disposal, you can manage by following approach.

	entity.remove building[ @@type ]
	do building[ @@dispose ]

As you may have suspected, calling dispose is a bit more destructive. In general the outcome is same, because `remove` call makes the `@@dispose` call too. If you want for some reason to prevent that, simply pass the `false` value as the second argument. Use this sparingly to avoid memory leaks and confusion.

	entity.remove cBuilding, false

#### Chaining commands

Methods `add`, `replace` and `remove` returns entity object itself. You can use it to chain the commands if you like.

	entity
		.add building
		.replace foundation
		.remove cWorker

When you don't need whole entity any more, you can remove it from the game simply by calling its `@@dispose` method. All components within entity are disposed as well.

	do entity[ @@dispose ]
	entity = null # Need only if reference is held somewhere

#### Change notifications

Entity object exposes couple of methods monitored with [NoMe](https://github.com/BlackDice/nome). You can attach to these to get notified about changes. Names of methods are self explanatory. All attached callbacks are invoked in the context of entity instance.

	Entity.componentAdded.notify (component) ->
	Entity.componentRemoved.notify (component) ->
	Entity.disposed.notify -> entity = this

#### Timestamp of change

As components have `@@changed` property, this is propagated to the entity too. It contains the most latest timestamp of the change. It is also updated when any component is added or removed from entity. Empty entity without component will have timestamp of 0.

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

Technically you can create multiple engine instances, but there is currently no way how to add created entity to the engine. All entities and node types are private to single engine. This is the current limitation of the implementation and it meant to be this way. If the need for multiple engines arises in future, we might implement it.

## Advertisement

Are you are interested in game development? Would you like to beat some challenges while participating on development of interesting and innovative WebGL multi-player game?

We require passion for game development and honest people, eg. don't make excuses about time if you don't want to really participate. You should have some knowledge of Javascript and web technologies in general. Knowing HTML + CSS isn't going to help you much here. You should be able to communicate in english or czech language.

We are small growing company filled with talented and friendly people. We are not dreamers, it's hard area of business, but we are determined to make this happen. Hop on the board and drop us mail *info (at) mrammor.com*.

## Tests

To have a look at tests outcome, you have to install node dependencies first (using `npm install`) and then you can simply run `npm test` to see the test outcome.

For development we are using amazing Test'em tool. Just install it globally (`npm install -g testem`) and then run in this directory (`testem`). Tests will run in Node environment by default and you can connect with any browser to see how the framework behaves in there.
