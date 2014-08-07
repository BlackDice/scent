# SCENT: A System-Component-Entity framework

*Make a great game with fresh scent. It smells really good !*

Scent is framework heavily based on the [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all of its properties in one big messy object. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

Please note that this is far from complete solution of "how to make the game". This is only small piece of the whole cake that needs to be used in much more robust environment to handle game requirements. However it is something that all games have in common no matter of genre.

## Terminology

Overview of the terms used in the framework.

The **Component** is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.

The **Entity** is any game object. It is composed of components designating the purpose of entity that way.

The **Node** is small subset of components owned by single entity and simplifies work of the systems.

The **System** is place for your game logic.

The **Engine** is meeting spot for all mentioned parts.

### Symbol usage

Framework is using Symbol structure as specified in EcmaScript 6. This is mainly to avoid collisions in created objects and also to store truly private states. All public symbols are accessible from `symbols.coffee` file. You can use these to get required values. Acknowledged notation exists for the symbols, it uses `@@` as prefix. Anytime when I am using this prefix be aware you have to use the symbol of that name from mentioned file.

## How it works

Basically you should define some *components* and add created instances of them to different *entities* while setting required data. Then you can let *systems* do their job with tremendous help of *nodes*. In the end, everything is nicely wrapped in the *engine*.

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's necessary to define component and designate what properties you want to manage for the component.

	cBuilding = Component 'building', ['floors', 'height', 'roofType']

First argument is the name of the component. It helps to identify what are you currently looking at and also to automate some other tasks. The resulting variable `cBuilding` is a **factory function** used to create component instance that can hold the data. 

You can completely omit list of properties. That is useful for components called **markers**. Name for these component should start with some word expressing state, like 'has' or 'is'.

	cHasRoof = Component 'hasRoof'
	cIsBulletproof = Component 'isBulletproof'

Factory function exposes some symbols. You might be interested in @@name to get the actual name of component.

	cBuilding[ @@name ] === 'building'

### Working with components

Once you have component defined, it's very easy to create instance of it and start using it. Let's use the `cBuilding` component from previous example.

	building = cBuilding()
	building.floors = 5
	building.height = 10

Factory function doesn't accepts any parameters. All values have to be set explicitly like shown. You don't need to set all properties. You cannot set properties you haven't been defined for the component. Those will be silently ignored and thrown away.

*Note that components are not classes thus avoid using keyword `new` in front of factory function. It doesn't change behavior thou, it's about performance.*

When you are done working with the component and it's not needed anymore, you should call its `@@dispose` method. This will free up any internal resources and remove values. You should also get rid of any possible references that could hold that component.

	do building[ @@dispose ]
	building = null

This approach is not needed if using components as intended. When removing component from entity, the component be disposed for you automatically.

### Entity as components collection

Components needs some space to live in. You might also want to tie together more of the different component types to represent particular game **entity**. Entity itself doesn't need any definition or configuration, it's just a container for components.

	entity = Entity()

#### Adding components

That's all that needs to be done. Lets `add` some component in there. Simply pass in the instance of component. You can call `add` method as many times as you want/need.

	entity.add building

Keep in mind, that adding component of the same type replaces existing one inside the entity. In cases where you want to do that, use `replace` method which doesn't produce warning message. It's for the semantics purposes so it's clear from the code, that component is supposed to be replaced.

	entity.replace building

#### Retrieving components

For the following methods you need to have access to original factory function of the component as it declares the type of component. First you might want to check if component is part of the entity using `has`. It returns boolean value.

	entityIsBuilding = entity.has cBuilding

To retrieve component object itself you can use `get` method. It will return `null` if component of that type is not present in the entity.

	building = entity.get cBuilding

Avoid calling `has` followed by `get`. For performance purposes use the following approach.

	if building = entity.get cBuilding
		building.floors += 1

And finally there is `remove` method to unchain the component from the entity. Note that by default the `@@dispose` method of the component will be called upon removal from entity. If you want to prevent that, simply pass the `false` value as the second argument. Use this with caution in cases when you want to transfer component to another entity.

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

#### Multi-player entity

As stated in the introduction, framework is made for use in multi-player game environment. Entity is prepared to this by having id property. This ID should be set by some kind of authority (like game server) and it can than be used to issue commands to work with these entities.

	serverEntity = Entity 'character123'

ID can be number or string, it's not constrained at all. Calling `Entity` with the same ID will return seamlessly the same entity.

*Note that this kind of entity is not pooled so avoid disposing and creating them again too much.* 

### Swimming in big entity pool

Since entity is supposed to represent even the tiniest game element, it is expected to have a lot of them. Most of the game logic is driven by some timing mechanism and having to lookup interesting entities to work with every time would be very cumbersome and inefficient. To solve this issue, the framework contains objects called **node**.

Node gives you distinguished list of entities that fulfills set of rules. These rules are based on set of components that entity **must** have to be considered *interesting*. All other entities are just ignored. You can think about this approach like specifying what kind of data has to exists together for you to be able work something out with them.

For each entity that fulfills given set of requirements, one node item is made and tightly coupled to that single entity. In the end you have nice and tidy list of entities having components you are interested in. You don't need to swim through whole pool to find what you need.

#### Define the node

All you need to do is to specify set of components you are interested in. That is done simply like this.

	nStructure = Node [cBuilding, cFoundation]

Resulting variable `nStructure` can be seen like simple node type similarly to component definition, but it is much more. Mainly it manages the internal list of node items that are made automatically based on created or modified entities.

Also note that if you are requesting node type with same set of components (order doesn't matter), the previously defined node type will be returned. It is generally quite fast operation, so don't hesitate to use it if you don't want to store node types all over the places.

#### Node meets entity

There are three methods on the node type object which can be used to notify about entity creation, update or removal. Note that when using default engine implementation (more on that later), **this is managed for you** and you don't need to worry about it.

	nStructure.addEntity entity
	nStructure.updateEntity entity
	nStructure.removeEntity entity

Generally the `updateEntity` is the smartest one and is able to decide if entity needs to be added, removed or just updated. However it's more costly in performance. If you know exactly what you want to do, use one of remaining appropriate methods.

Passed entity object is be evaluated for current components and if all of them are present, node item is made (or updated/removed). You are not getting any feedback at this point (except errors for invalid entity). Instead the internal list is updated and you can access that as a whole later.

#### Accessing nodes

In most of the scenarios you are interested in the whole list of node items and you want iterate through them.

	loopNodes = (node, idx) ->
		# Do something with the node
	
	nStructure.each loopNodes

##### It's linked list

Internally the list of node items is held in linked list structure. In case you need more control over the looping, read on. You have access to the beginning and also end of the list.

	nStructure.head # first node item in the list
	nStructure.tail # last node item in the list

Every node item has properties referencing a next and previous item from the list. This allows you to make loops like this if you need more control over `each` method.

	node = nStructure.head
	while (node)
		# Do something with the node
		node = node[ @@next ]

Note that `@@next` and `@@prev` properties are `null` in case they would be pointing to itself. Eg. one node in the list has no *next*, first node of two item list has no *prev*, etc... 

#### Access to components

Node item is directly linked to entity that through `@@entity` property. You could access components from there. Luckily for your convenience the node item contains components directly. Names of components are used here to define property names for easy access.

	loopNodes = (node) ->
		node.building.floors += 1 # directly increase floors of cBuilding component
		if node.foundation.material = 'steel' 
			do node[ @@entity ][ @@dispose ] # remove the entity from the game

### Need for logic

Entity itself is a nice package of related data, but it doesn't really do anything. For that purpose we need another piece of the puzzle - **systems** (note the plural). There should be many systems, each responsible for some of the game mechanics.

Compared to other parts of the framework, defining the system is far more complex, but you could have expected that. We were mostly handling data so far. Following is recommended way how to setup the system.

	module.exports = System 'name', (engine) ->

		# This is the place for initialization logic before the system
		# is actually managed by the engine. Anything that is supposed 
		# to stick with the system for the eternity is supposed to be here.

		install = ->
			# This method is called when the system is installed into engine.
			# It's good spot to attach event listeners you might want to use

		uninstall = ->
			# Opposite of install, cleanup the resources that were created
			# during installation. This is important method for systems
			# that can be deactivated during runtime when they are not
			# needed.

		update = (timestamp, delta) ->
			# Place for your timed logic based on fixed timestep.
			# Update data in components that belongs to logic of this system

		render = (timestamp, delta) ->
			# Very similar to update method, but used to actually draw stuff
			# on the user screen.

		finish = ->
			# Method called when all systems run their update loop. 
			# It can be used to check for new nodes and entities and
			# prepare them for the next round.

		return {install, uninstall, update, render, finish}

As you can see there are 5 methods supported by system. All of them are absolutely optional and if you have nothing to put in there, it's recommended to omit them. Most basic system could look like this:

	module.exports = System 'basic', (engine) ->

		update = (timestamp, delta) ->

		return {update}

