# Node is the hero

Since entity is supposed to represent even the tiniest game element, it is expected there will be a lots of them. Entity doesn't have any type to be easily identified and looked up. Here comes the Node that helps to categorize entities based on their component composition.

Node gives you distinguished list of entities that fulfills set of rules. Currently these rules are based on set of components that entity **must** have to be considered *interesting* for such list. All other entities are just ignored.

You can think of it like converting entity to specific type which is defined by the node (class). It's not real conversion thou and single entity can be recognized by many different nodes.

## Define the node type

This is very similar to Component, but node type doesn't have any name. All you need to do is to specify set of components you are interested in. That is generally done like this.

```js
	var nStructure = new Scent.Node([cBuilding, cFoundation]);
```

Since node type doesn't know anything about your defined component types, you have to pass in the actual type objects. The list will be silently filtered for duplicates and invalid objects. Error is thrown if at least one valid component type is not found.

## Handling entities

Defined node type contains internal list of *node items*. Each node item is tightly coupled to single entity and can be used for easier access to the components (more on that later).

### Adding entity

Calling `addEntity` method of node type instance will check if entity fulfills the expectation by that node type and in that case it will be added to the list.

```js
	var eStructure = new Scent.Entity([new cFoundation, new cBuilding]);
	nStructure.addEntity(eStructure);
	nStructure.size === 1 //true
```

### Removing entity

Passed entity is checked against node type constraints again and removed **only if** entity no longer fulfills expectations. Otherwise it will stay on the list no matter what.

```js
	// following example above...
	nStructure.removeEntity(eStructure);
	nStructure.size === 1 // still in there
	eStructure.remove(cFoundation);
	nStructure.removeEntity(eStructure);
	nStructure.size === 0 // now it's gone
```

This is important to realize as node type isn't just plain list which you can modify freely. It has its rules!

### Updating entity

Method ˙updateEntity˙ will conveniently call `addEntity` or `removeEntity` depending on presence of that entity in the list. It can be used in the situation when you are not sure what happened to the entity and just want to check if entity is supposed to be on the list.

### Checking the constraints

If you want to simply check node type constraints against particular entity but without actually modifying the internal list, you can call `entityFits` method returning true/false.

## Accessing node items

Usually you will be having piece of logic that works with set of components. You really don't need to care about single items in the node type list. Too loop through node items use `each` method.

```js
	var loopNodes = function(node, timestamp) {
		node.entityRef // points to entity
	};

	nStructure.each(loopNodes, timestamp);
```

The `each` method accepts optional additional arguments that are passed in the callback after node argument.

### Finding particular node item ###

In some cases you might be interested in a single node item based on some conditions. Use `find` method to achieve this as it will stop looping once the required node item is found.

```js
	var findPredicate = function(node, id) {
		return (node.identity.id == id);
	};

	var foundNode = nStructure.find(findPredicate, seekedId);
```

Once the predicate function returns true, loop is stopped and found node item returned. If no item is found, a `null` is returned.

### Access to components

Node item is directly linked to entity. You can access components as usual with `node.entityRef.get()` method. Luckily for the convenience the node item also contains properties with required component names that are **lazily** evaluated to component instance contained within entity.

```js
	node.building.floors += 1; // directly increase floors of cBuilding component
	if (node.foundation.material == 'steel') {
		node.entityRef.dispose() // remove the entity from the game
	}
```

Lazily evaluation conserves some memory and time. It means that anytime you ask for eg. `node.foundation` it runs the `node.entityRef.get(cFoundation, true)` command. This also ensures that you are always getting current component from the entity.

Note the `true` argument which tells entity to return component even if it is being disposed currently. This will come in handy when you are doing something on the event of node item removal.

## Change notifications

Sometimes it might be useful to know that new node item has been added to particular node type to make some kind of setup based on entity composition. This can be achieved easily like this:

```js
	nStructure.onAdded(function(node) {
		node.entityRef.add(new cMoving);
	});
```

There is also counterpart for a removal when eg. component is removed from entity or even when whole entity is about to die.

```js
	nStructure.onRemoved(function(node) {
		node.entityRef.remove(cMoving);
	});
```

Note that callbacks for onAdded and onRemoved are *not invoked immediately* when creation or removal happens. Changes are stacked up and released when `finish()` method of node type is invoked.
