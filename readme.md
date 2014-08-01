# SCENT: A System-Component-Entity framework

Scent is framework based on [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all its properties together. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Terminology

Overview of the terms used in the framework.

The **Component** is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.

The **Entity** is ... *TBD*

The **System** is ... *TBD*

The **Node** is ... *TBD*

The **Engine** is ... *TBD*

## How it works

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's necessary to define component and designate what properties you want to manage for the component. You need **at least one property**. Only strings are accepted.

	cBuilding = Component ['floors', 'height', 'roofType']

The resulting variable `cBuilding` is a function used to create component object that can accept data (*more on that later*). There is couple of reserved words you cannot use for property name. Namely `constructor` and `dispose`. Error will be thrown when using any of these.

Sometimes you might need components called **markers**. These usually doesn't need any properties. However to keep the design simple, you can use following approach.

	cIsCollidable = Component 'isCollidable'

If you actually store any data in that property is up to you. Existence of that property also helps for debugging purposes. Simply by calling `toString` on the defined constructor function you get nice list of defined properties so you can easily identify what component is that.

### Working with components

Once you have component defined, it's very easy to create one and start using it. Let's use the `cBuilding` component from previous example.

	building = cBuilding()
	building.floors = 5
	building.height = 10

Constructor function doesn't accepts any parameters. All values have to be set explicitly like shown. You don't need to set all properties, that's up to you and you have take care of that when designing systems. You cannot set properties you haven't defined for the component. Those will be silently ignored and thrown away.

Note that components are not classes thus avoid using keyword `new` in front of them.

When you are done working with the component and it's not needed anymore, you should call its `dispose` method. This will free up internal resources. You should also get rid of any possible references that could hold that component.

	building.dispose()
	building = null

This approach is not needed if using components as intended. When removing component from entity, the component be disposed for you automatically.