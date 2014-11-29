## Entity as component collection

Components needs some space to live in. Usually components are related somehow together and represents particular game **entity**. Entity itself doesn't need any definition or configuration, it's just a container for components.

```js
	var entity = new Scent.Entity()
```

## Adding component

Entity without components is just empty meaningless shell. Lets `add` some component in there. Simply pass in the instance of component. You can call `add` method as many times as you want, but only with different component types.

```js
	entity.add(building);
	entity.add(onFire);
	entity.add(damaged);
```

You can also add components to entity during its creation by passing them to constructor in array.

```js
	eStructure = new Scent.Entity([building, onFire, damaged]);
```

## Replacing component

As mentioned above, you cannot use `add` method to replace component of the same type. This is merely to avoid unexpected behavior. In case where the replacement of the component is desired, simply use `replace` method.

```js
	entity.replace(new cOnFire);
```

To debug issues coming from calling `add` while `replace` should be called use "scent:entity" filter for the [debug](https://www.npmjs.org/package/debug) module.

## Removing component

To remove component from the entity you need reference to its type.

```js
	eStructure.remove(cOnFire);
```

Note that component is not lost yet. Basically it's just marked as disposed, but it can be retrieved if needed. However if you use `add` method after removing component type, this will be lost forever.

## Retrieving components

Similarly to `remove` method, you need component type reference. First you might want to check if component is part of the entity using `has`. It returns boolean value.

```js
	var entityIsBuilding = entity.has(cBuilding);
```

To retrieve component instance itself you can use `get` method. It will return `null` if component of that type is not present in the entity.

```js
	var building = entity.get(cBuilding);
```

As for the components that were removed with `remove` method, these can be retrieve by the `has` and `get` if you specify second argument as `true` value.

```js
	entity.remove(cBuilding);
	var noBuilding = entity.has(cBuilding);
	var itWasBuilding = entity.has(cBuilding, true);
```

### Retrieve all components

In case you want to retrieve whole list of component instances, use `getAll` method. It will return array of component instances. It may be useful mainly for serialization purposes.

```js
	var components = entity.getAll();
```

For a small performance gain you can also supply target array in first argument and it will be filled instead of creating new one.

```js
	var components = [];
	entity.getAll(components);
```

## Chaining commands

Methods `add`, `replace` and `remove` returns entity object itself. You can use it to chain the commands if you like.

```js
	entity
		.add(building)
		.replace(foundation)
		.remove(cWorker);
```

## Pooling entities

Since there is no type of entity, there is single common pool for all disposed and released entities. To reuse entity from the pool simply invoke static `pooled` method instead of `new` keyword.

```js
	var eParticle = Scent.Entity.pooled([component]);
```

Currently there is no way how to disable this feature. Trying to implement own pooling mechanism can result in unexpected behavior.

## Destroy entity

To completely get rid of entity and contained components simply call `dispose` method. It will not destroy anything right away, but merely mark the entity as disposed. Disposed entity cannot be modified by adding/replacing/removing components.

```js
	entity.dispose()
	entity[ Scent.Symbols.bDisposing ] === Date.now()
```

### Releasing entity

Entity has it's `release` method that will release any components that were within entity and entity will be returned to the pool for future use.

#### Change notifications

Entity object exposes couple of methods monitored with [NoMe](https://github.com/BlackDice/nome). You can attach to these to get notified about changes. Names of methods are self explanatory. All attached callbacks are invoked in the context of entity instance.

```js
	Entity.componentAdded.notify(function(component) {
		entity === this
	});
	Entity.componentRemoved.notify(function(componentType) {
		entity === this
	});
	Entity.disposed.notify(function() {
		entity === this
	});
```

#### Timestamp of change

Similarly to the Component, the Entity has `changed` property reflecting latest timestamp of the change. Any change to component data or adding/removing component will update this timestamp.