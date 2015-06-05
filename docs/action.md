# Actions in the field

Games are about interaction of the user/player - some kind of events happening in time. Some events can be triggered by game mechanics (eg. moving npc character, starting rain...). Such logic is wrapped by small objects called *actions*.

Actions are not like events. You might know patterns where the action is triggered and appropriate handler is executed right away. Instead the actions are stacked and handlers executed when the time is appropriate.

## Defining action type

Each action type has to be named to be easily identifiable.  Type of the name variable is not enforced and you might even use object as identifier.

```js
	var aMove = new Scent.Action('move');
```

This creates the container for list of actions. The list is internal and cannot be accessed directly.

## Triggering action

To add action into the list, simply call `trigger` method. First argument is expected to be data object or actually anything you like. It is not managed in any way, just made available to you in `data` property on action instance.

```js
	aMove.trigger({x: 10, y: 20, z: 30});
```

### Meta data

Also second argument can be supplied and it's content will be available in `meta` property on action object. This can be used to distinguish data, that are not transmitted over network.

```js
	aMove.trigger(
		{x: 10, y: 20, z: 30},
    	{origin: this}
	);
```

## Processing actions

As mentioned above, actions are not processed immediately in time of triggering. This conforms to paradigm established by nodes and fits into general sense of the framework.

Currently there are no means to access single actions from the list nor remove them. You can only iterate list of actions.

```js
	aMove.each(function(action) {
	});
```

Optionally you can pass in the context object in second argument for the callback invocation.

The `each` method doesn't loop if there no actions present. However for performance reasons you might want to see number of actions in there and decide if its worth processing.

```js
	aMove.size
```

## Getting action data

As mentioned before, all data are simply made accessible through properties on action instance when iterating.

```js
	aMove.each(function(action) {
		action.data.x is 10
		action.data.z is 30
		action.meta.origin is <Object>
	});
```

Word of warning. Don't use action object outside of the scope of the `each` method. When the `finish()` method is called (see below), the properties of action object are reset. You can keep actual data/meta objects if you need, but not the actual action.

### Action timestamp

Often you might need to know when the action has been triggered so you can apply some time calculations. Each action object has automatic `time` property containing environment timestamp set when actual trigger happened.

```js
	var lastTime = Date.now();
	aMove.each(function(action) {
		action.time - lastTime;
	}
```

## Immutable actions

Internal list of actions is immutable during the processing.
List will stay exactly the same until the `finish()` method is called. This creates another feel of consistency as no executed handler can actually trigger another action and mess with list.

You may ask what happens to actions that were triggered during processing. These are simply buffered and once the `finish()` is called, they will be flushed to the main list.
