# SCENT: A System-Component-Entity framework

Scent is framework based on [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all its properties together. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Terminology

Overview of the terms used in the framework.

The **Component** is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.

The **Entity** is any game object. It is composed of components designating the purpose of entity that way.

The **System** is ... *TBD*

The **Node** is ... *TBD*

The **Engine** is ... *TBD*

## How it works

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's necessary to define component and designate what properties you want to manage for the component.

	cBuilding = Component 'building', ['floors', 'height', 'roofType']

First argument is the name of the component. It helps to identify what are you currently looking at and also to automate some other tasks. The resulting variable `cBuilding` is a **factory function** used to create component instance that can hold the data. 

You can completely omit list of properties. That is useful for components called **markers**.

	cIsCollidable = Component 'isCollidable'

Name of the component is available in the read-only property `name`.

*Note that there is couple of reserved words you cannot use for property name. Namely `component` and `dispose`.*

### Working with components

Once you have component defined, it's very easy to create instance of it and start using it. Let's use the `cBuilding` component from previous example.

	building = cBuilding()
	building.floors = 5
	building.height = 10

Factory function doesn't accepts any parameters. All values have to be set explicitly like shown. You don't need to set all properties. You cannot set properties you haven't been defined for the component. Those will be silently ignored and thrown away.

*Note that components are not classes thus avoid using keyword `new` in front of factory function. It doesn't change behavior thou, it's about performance.*

When you are done working with the component and it's not needed anymore, you should call its `dispose` method. This will free up any internal resources and remove values. You should also get rid of any possible references that could hold that component.

	building.dispose()
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

	entity.remove cBuilding # calls building.dispose()
	entity.remove cBuilding, false

Methods `add`, `replace` and `remove` returns entity object itself. You can use it to chain the commands if you like.

	entity
		.add building
		.replace foundation
		.remove cWorker

When you don't need whole entity any more, you can remove it from the game simply by calling its `dispose` method. All components within entity are disposed as well.

	entity.dispose()
	entity = null # Need only if reference is held somewhere
