# Engine smells good

If you have read closely articles about other framework parts, you may have noticed they are not really much tied together. It would require some effort to make all of it useful. Engine is here to help with such a heavy lifting. Here goes list of features:

 * Offers the way to run game loop updates.
 * Register systems initialized upon engine start.
 * Store node types and action types for easy access.
 * Add entities which are passed to node types.

## Create the engine

The simplest way to create engine instance looks like this. This will provide you with the basic functionality as it is explained below.

```js
	var engine = new Scent.Engine();
```

Note that engine instance is frozen (with `Object.freeze`) thus you cannot do any changes to it. This is simply security policy. Later you will learn how to actually extend the engine in very easy way.

## Update cycle and the flow

Most important part of the engine is synchronizing work of other framework parts. This is called **update cycle**. Once you invoke `update` method of the engine, the following will happen in this exact order:

 1. Actions are processed and handlers are called
 2. Node types are updated with current set of entities
 3. Handlers added by onUpdate are triggered.

```js
	engine.update(timestamp);
```

Arguments passed in the `update` call are optional and completely unrestrained. These will be just handed over to `onUpdate` handlers. To register such handler you can do this (even repeatedly) within system initializer.

```js
	engine.onUpdate(function(timestamp) {

	});
```

## Action in the engine

Engine wraps action functionality and provides somewhat easier interface than the one provided by Action itself. As the bonus, the name of action type doesn't need to be string since ES6 Map is used underneath. You can use any object or identifier you like.

### Triggering actions

You can easily trigger new action with `triggerAction` method.

```js
	engine.triggerAction('boom', {radius: 500, power: 100});
	var bPrivateAction = new Symbol('private action');
	engine.triggerAction(bPrivateAction);
```

Be aware that even if you create such action in the middle of update cycle, it will not be processed sooner then in the beginning of the next update cycle.

### Processing actions

To make the system (or any other piece of code) to process action, simply call `onAction` method. This can be done anywhere. Basically it registers your callback function and it will be called for every action available whenever it is appropriate.

```js
	engine.onAction('boom', function(action) {
		action.data.radius
	});
```

These callbacks are invoked at the **beginning of update cycle**. Even before node types are updated. You actions can easily create or modify entities and node types will be able to see such changes.

Once single action type has run through all registered callback functions, the `finish()` method of action type will be called which effectively clears the list of processed actions and prepares action types for the next round.

Note that trying to trigger action without single registered handler will basically throw away such actions. This is to prevent stacking up in memory without anyone interested.

## Access to nodes

Engine stores node types for you. All node types you access through the engine are remembered and you can access them from anywhere you like.

```js
	var nStructure = engine.getNodeType([cBuilding, cFoundation]);
```

As mentioned above, nodes are updated during update cycle after actions were processed. To actually loop through available node types, you should proceed like this:

```js
	var loopStructureNode = function(node, timestamp) {

	};
	engine.onUpdate(function(timestamp) {
		nStructure.each(loopStructureNode, timestamp);
	});
```

You can also use `onAdded` and `onRemoved` method to register your handlers. These will be invoked after the node types were updated with entities. Recursive behavior is implemented to allow eg. `onRemoved` handler to call `dispose` method for some entity which could cause another update to some other node types.

## Entity management

Engine keeps the list of all entities for you. It also automatically informs existing node types about these. All you need to do is call method `addEntity`.

```js
	var building, foundation;
	var eCorporateBuilding = engine.addEntity([
		building = new cBuilding,
		foundation = new cFoundation
	]);
	building.floors = 10;
	foundation.material = 'stone';
```

There is no direct method for removal of entity from engine. Instead when you call `entity.dispose()`, it will eventually remove entity from engine as well.

## Add the systems

System initializers are not invoked immediately when added to the engine. You have to start the engine to do that in a batch.

```js
	var sInput = Scent.System.define('input', function() {

	});
	function sDisplay($engine) {

	};
	engine.addSystem(sInput);
```

As you may see, there is no need to use System.define call. Instead you can create named function and it will be used as a system. Even if you create anonymous function, it will be given generated name, so no worry.

Above method supports only single system passed in. You have to call it for each system separately. For the sake of simplicity, there is also `addSystems` method which accepts array of system initializers.

```js
	engine.addSystems([sInput, sDisplay, sMovement]);
```

## Start the engine

Now when your engine is pumped up with systems, you can start it. It will call all system initializer functions to let them do their setup. There is currently no way how to actually stop the engine itself, but if you stop invoking an `update` method, the engine will be just idling.

```js
	engine.start(done);
```

Argument `done` is here to support asynchronous initialization of systems. When everything is loaded and ready, it will be called in error-first callback style. System can be made asynchronous using an injections.

### Injections for system

You may have heard about term *dependency injection*. It's rather simple but powerful idea. Scent engine provides this to power up systems more easily. As you may have noticed earlier, system initializer function isn't initially expecting any arguments. Since each system is different and has different needs, it would be cumbersome to have fixed arguments in there.

```js
	Scent.System.define('powerful', function($engine) {
		$engine.onUpdate(function() {

		});
	});
```

Engine will analyze the name of arguments you have used for function declaration and provide configured values upon its invocation. Order of the arguments or their number doesn't matter here. There are two injections that are provided for you by default. First can be seen in example above, it's engine instance.

Note the `$` prefix. If you are about to minify your code, there is usually some kind of shortening variable names. This would obviously break dependency injection here since it is based on variable names. We recommend it as good practice to prefix all injected variables so you can tell your minifier what variables should stay in place. Without prefix you would be keeping all occurrences of *engine* which might be quite a lot.

### Asynchronous system

Second built-in injection is named `done` and once used in system initializer arguments, it marks the system as *asynchronous*. It is expected from you to call this callback whenever the system is ready.

```js
	Scent.System.define('async', function($done) {
		makeAsyncCall($done);
	});
```

Callback is error-first style and in case you pass anything truthy in first argument, it will interrupt engine start and the result is propagated to callback from the `start` method. Any arguments beside first one are ignored (at least for now).

Please note that once the engine is started, adding asynchronous system doesn't propagate its *done* state anywhere. You would have to ensure this on your own. Thus we recommend adding all asynchronous systems before engine is started.

## Extensible engine

Now it's time to go deeper as so far the engine is nice and powerful, but also too closed for your taste. You can create extension to engine simply like this.

```js
	var engine = new Scent.Engine(function(engine) {
		// Here goes any extensions and setup
	});
```

Passed function is called immediately with created engine instance except it is not frozen yet in here. You can do anything you like with the engine instance. Once this function ends, engine instance is frozen and cannot be extended further.

### Custom injections

During engine initialization you can call `provide` function passed in arguments to actually setup your own injection for system initializers.

```js
	var engine = new Scent.Engine(function(engine, provide) {
		provide('$app', appInstance);
	});
```

Name defined here corresponds to the name of argument you need to use in your system initializer function. You can specify any static value that you want to provide, eg. object with shared settings that some systems might need.

If you specify function, it will be called every time when some system asks for such injection. You are expected to return some value that will be actually injected into the system.

```js
	var setupFunction = function(engine, systemInitializer) {
		// Returned value is passed to system initializer
		return getConfigForSystem(systemInitializer[ @@name ]);
	};

	var engine = new Scent.Engine(function(engine, provide) {
		provide('setup', setupFunction);
	});

	engine.addSystem(Scent.System.define('withSetup', function(setup) {
		// Your system specific config is ready in here
	});
```

## Multiple engines?

Technically you can create multiple engine instances, but they do not share any resources except component types (which are basically global). You cannot share entities with multiple engine simply because there is no built-in method to add existing entity in the engine instance.
