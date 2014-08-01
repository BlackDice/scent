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

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's necessary to define component and designate what properties you want to manage for the component. You need **at least one property**. Only strings are accepted.

	cBuilding = Component ['floors', 'height', 'roofType']

The resulting variable `cBuilding` is a function used to create component object that can accept data (*more on that later*). There is couple of reserved words you cannot use for property name. Namely `constructor`, `dispose` and `toString`. Error will be thrown when using any of these.

Sometimes you might need components called **markers**. These usually doesn't need any properties. However to keep the design simple, you can use following approach.

	cIsCollidable = Component 'isCollidable'

If you actually store any data in that property is up to you. Existence of that property also helps for debugging purposes. Simply by calling `toString` on the defined factory function you get nice list of defined properties so you can easily identify what component is that.

### Working with components

Once you have component defined, it's very easy to create one and start using it. Let's use the `cBuilding` component from previous example.

	building = cBuilding()
	building.floors = 5
	building.height = 10

Factory function doesn't accepts any parameters. All values have to be set explicitly like shown. You don't need to set all properties, that's up to you and you have take care of that when designing systems. You cannot set properties you haven't defined for the component. Those will be silently ignored and thrown away.

Note that components are not classes thus avoid using keyword `new` in front of factory function. It doesn't change behavior thou. It just created and dumps unnecessary objects internally.

When you are done working with the component and it's not needed anymore, you should call its `dispose` method. This will free up internal resources. You should also get rid of any possible references that could hold that component.

	building.dispose()
	building = null

This approach is not needed if using components as intended. When removing component from entity, the component be disposed for you automatically.

### Entity as collection components

Components on it's own are quite useless. You should gather them together in the object called entity. Entity itself doesn't need any definition or configuration, it's really just container. So to **create entity**, just call the function.

	entity = engine.createEntity()

Specifics of the `createEntity` method will be revealed when discussing game engine itself. For now this is all you need to know about creating entities. Lets add some component in there.

	entity.add building

That's it, no big magic around. You can call `add` method as many times as you want/need. However keep in mind, that adding component of the same type simply replaces it inside entity. If that's what you intend to do, rather use `replace` method which doesn't produce warning message.

	entity.replace building

For the following methods you need to have access to original factory function of the component as it declares the type of component. First you might want to check if component is part of the entity using `has`. It returns boolean value.

	entityIsBuilding = entity.has cBuilding

To retrieve component object itself you can use `get` method. It will return `null` if component of that type is not present in the entity.

	building = entity.get cBuilding

Finally there is `remove` method to unchain the component from the entity. 

	entity.remove cBuilding

Note that by default the `dispose` method will be called on component object upon removal from entity. If you want to prevent that, simply pass the `false` value as the second argument.

	entity.remove cBuilding, false

Methods `add`, `replace` and `remove` returns entity object itself. You can use it to chain the commands if you like.

	entity
		.add building
		.replace foundation
		.remove cWorker

When you don't need entity any more, you can remove it from the game simply by calling `dispose` method. All components withing entity are disposed as well.

	entity.dispose()
	entity = null
