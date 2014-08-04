# SCENT: A System-Component-Entity framework

*Make a great game with scent. It smells really good !*

Scent is framework heavily based on the [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all of its properties in one big messy object. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Terminology

Overview of the terms used in the framework.

The **Component** is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.

The **Entity** is any game object. It is composed of components designating the purpose of entity that way.

The **Node** is small portion of the entity 

The **System** is ... *TBD*

The **Engine** is ... *TBD*

### Symbol usage

Framework is using Symbol structure as specified in EcmaScript 6. This is mainly to avoid collisions in created objects and also to hide some internal states. All public symbols all accessible from `symbols.coffee`. You can use these to get required values. Acknowledge notation exists for the symbols, it uses prefix `@@`. Anytime I am using this prefix be aware you have to use the correct symbol from mentioned file.

## How it works

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's necessary to define component and designate what properties you want to manage for the component.

	cBuilding = Component 'building', ['floors', 'height', 'roofType']

First argument is the name of the component. It helps to identify what are you currently looking at and also to automate some other tasks. The resulting variable `cBuilding` is a **factory function** used to create component instance that can hold the data. 

You can completely omit list of properties. That is useful for components called **markers**. Name for these component should start with some word expressing state, like 'has' or 'is'.

	cHasRoof = Component 'hasRoof'
	cIsBulletproof = Component 'isBulletproof'

Factory function exposes some symbols. You might be interested in @@name to get the actual name of component.

	cBuilding[@@name] === 'building'

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

And finally there is `remove` method to unchain the component from the entity. Note that by default the `dispose` method of the component will be called upon removal from entity. If you want to prevent that, simply pass the `false` value as the second argument. Use this with caution in cases when you want to transfer component to another entity.

	entity.remove cBuilding # calls building[ @@dispose ]
	entity.remove cBuilding, false

Methods `add`, `replace` and `remove` returns entity object itself. You can use it to chain the commands if you like.

	entity
		.add building
		.replace foundation
		.remove cWorker

When you don't need whole entity any more, you can remove it from the game simply by calling its `dispose` method. All components within entity are disposed as well.

	do entity[ @@dispose ]
	entity = null # Need only if reference is held somewhere

#### Multi-player entity

As stated in the introduction, framework is made for use in multi-player game environment. Entity is prepared to this by having id property. This ID should be set by some kind of authority (like game server) and it can than be used to issue commands to work with these entities.

	serverEntity = Entity 'character123'

ID can be number or string, it's not constrained at all. Calling `Entity` with the same ID will return seamlessly the same entity.

*Note that this kind of entity is not pooled so avoid disposing and creating them too much.* 

### Need for logic

Entity itself is a nice package of related data, but it doesn't really do anything. For that purpose we need another piece of the puzzle - **systems** (note the plural). There should be many systems, each responsible for some of the game mechanics. System needs a data to work with and those are stored in components.

Generally it would be very cumbersome if every system would need to loop through all entities in the game engine and check if they have components that are interesting for that system. To solve this issue, the framework contains objects called **node**.

Each node is tightly coupled to exactly one entity, but it exists only if entity has required set of components. For every entity there can be numerous nodes. In the end you have nice and tidy list of entities having components you are interested in. You don't need to loop through all of them and filtering them every time.

#### Define the node

Similarly to components, node has to be defined first too. You have to designate what components are you interested in. This is as simple as it can possibly be.

	nStructure = Node [cBuilding, cFoundation]

Similarly to components, `nStructure` variable represents node type, but it's not a function you can call. This is different to components as node instances are created internally. There are two methods on the returned object which can be used to notify  about entity creation or removal.

	nStructure.addEntity entity
	nStructure.removeEntity entity

There is no output from these methods. In case that entity fulfills the requirements, node instance will be created and added to the internal list. For performance reasons it is linked list structure and you have direct access only to first and last node instance.

	nStructure.head # first node in the list
	nStructure.tail # last node in the list

Each node instance has got `next` and `prev` properties pointing to its neighbors in the list. This can be used to iterate over the list. To keep this DRY and simple there is convenience method `each` that simplify looping for you. 

	nStructure.each (node) ->
		# Do something with the node

		# If you want to stop the loop for some reason...
		return false

Having node instance gives you direct access to requested components and also to the entire entity in case you want to work with that somehow. Names of components are used here to define property name for easy access.

	node = nStructure.list.head
	node.building.floors += 1 # directly increase floors of cBuilding component
	if node.foundation.material = 'steel' 
		node.entity.dispose() # remove the entity from the game

Of course you can still access components out of the defined set directly through entity property, but it's not recommended and you should only access components you are expecting to be in there.
