# S(*ystem*) C(*omponent*) Ent(*ity*)

Scent is library based on [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. It's simplified in some cases and made more strict where it matters.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all it's properties together. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Terminology

Overview of the terms used in the library.

The **Component** is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.

The **Entity** is ... *TBD*

The **System** is ... *TBD*

The **Node** is ... *TBD*

The **Engine** is ... *TBD*

## How it works

### Defining the component

This is usually the first step in the design of the game structure. To be able to do anything you need some place to store data. That's the role of the component. However before you can store some data in there, it's viable to define component and tell what properties you want to manage for the component.

	cBuilding = Component ['floors', 'height', 'roofType']

The resulting variable `cBuilding` is a function used to create component object that can accept data. Keep in mind that you can set only properties from the defined set. Anything else is just silently thrown away. This is precaution to avoid components with different structures

Sometimes you might need components called *markers*. These usually doesn't need any properties. However to keep the design the same, you have to define at least one property.

	cIsCollidable = Component 'isCollidable'

If you actually store any data in that property is up to you. Existence of that property also helps for debugging purposes. Simply by calling `toString` on the defined function you get nice list of defined properties so you can easily identify what component is that.