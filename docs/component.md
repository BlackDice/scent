# Component is data unit

The first step in the design of the game structure is to have some **place to store the data**. Component would serve this purpose very well.

## Defining the component

To define component type you have to designate what properties you want to manage in there.

```js
	var cBuilding = new Scent.Component('building', 'floors height roofType');
```

 * First argument is the name of the component. It helps to identify what are you currently looking at and also to automate some other tasks (see Node).

 * Second argument is optional and contains list of properties you want to define for a component type.

   - Property name has to start with letter and be composed of alphanumeric characters only.
   - Properties with non-alphanumeric characters are completely omitted.
   - Any whitespace characters are used as delimiter.
   - Duplicates are automatically removed.

The resulting variable `cBuilding` is a **component type** and by invoking it you can create component instance that can actually hold the data. You might also need this type to do some checks (eg. entity methods, see below).

### Marker component

You can completely omit list of properties and effectively create component type called **marker**. Name for marker components should start with some word expressing state, like 'has' or 'is', but it's not enforced in any way.

```js
	var cHasRoof = new Scent.Component('hasRoof');
	var cIsBulletproof = new Scent.Component('isBulletproof');
```

## Identity number

Each component type is assigned identity number upon creation. It is mainly used to easily identify group of component types (eg. by Node). You can also use it for some kind of storage mechanism since name of component type doesn't need to be unique.

Identity number is retrieved from internal list of prime numbers, currently ending at number 7919. That's exactly 1000 component types available to use. If there is ever need for more component types, we might consider some more robust solution. For now this is pre-generated list for performance reasons.

The list is static to avoid collisions. Every constructed component will grab the next number from the list and reserve it for that component type.

Component type cannot be retrieved by identity number as there is no internal storage for these. It's up to you to handle this.

### Overwriting identity

For more complex architecture you might need to specify identity of component type by yourself. If you try to pass in number that is already taken or not present in the internal list, error will be thrown.

```js
	var cPerson = new Scent.Component('person', '#677 head torso limbs #1');
	cPerson.typeIdentity === 677; // true
```

Simply prefix your identity number with `#`. It can be anywhere in properties list. You can specify only single identity. First occurrence of the pattern is taken into account, any subsequent is ignored.

## Exposed properties

Component type exposes some properties. All of these are read-only.

 * *typeName* is actual name of component you have passed in first argument.
 * *typeFields* is array of parsed property names from the second argument filtered out for duplicates.
 * *typeIdentity* identity of the component type (see above).
 * *typeDefinition* definition of the component for serialization purposes ('#23 floor wall roof')

## Working with components

Once you have component type, you can instantiate it with `new` keyword.

```js
	var building = new cBuilding({
		floors: 2,
		height: 8
	});
```

or

```js
	var building = new cBuilding();
	building.floors = 5;
	building.height = 10;
```

You don't need to set all properties and you cannot set properties you haven't defined for the component type. Those will be silently ignored and thrown away.

### Dynamically set data

There is another supported way of setting data for a component. This is intended for serialization mechanics more than general usage as it is hard to read without looking at the order of defined properties. Following gives the same result as above example.

```js
	var building = new cBuilding([5, 10]);
```

Note that passed array is kept for the pooling purposes. Be warned that *keeping reference* to it may cause unexpected issues. If you want to use/modify these data somewhere else, you better clone the array for the component.

## Pooling components

In many situations you may have components that are being used for quite short time. It would be waste of resources to recreate these every time. For such components instead of the `new` keyword you may use `pooled` static method.

```js
	var drop = cDropOfWater.pooled();
	drop.size = 'huge'
```

When the component is created using `pooled` method for the first time, internal pool is made. Releasing (see below) component instance of that type stores it and next call to `pooled` method resultes instance from the pool.

## Destroy component

When you are done with the component and it's not needed anymore, you should call its `@@dispose` method which marks component as disposed at lets other parts of framework know about it.

```js
	building[ Scent.Symbols.bDispose ]()
	building[ Scent.Symbols.bDisposing ] === Date.now()
```

### Releasing component

To actually free up the resources used by a component there is separate `@@release` method which resets component instance to the initial state and stores it in the pool for the future usage. For that reason you should clear any references to the component you may have elsewhere.

```js
	building[ Scent.Symbols.bRelease ]()
	building = null
```

## Observe changes

Currently there is no way to actually observe change to data of the component because by the nature of the framework you should not care about that and simply work with data you have available at the time.

However there is `@@changed` property on the component instance being equal to timestamp when the component data changed for last time. If there was no change, the 0 (zero) is returned.
