# System holds logic

System is basically just wrapper around the piece of code representing game mechanics. It can be really simple. Over complicated systems are much harder to read, test, maintain and debug. Keep that in mind when designing your systems.

## Defining the system

System doesn't need to be instantiated like other parts of the framework. Thus there is simply just `define` method exported.

```js
	var sWorker = Scent.System.define('worker', function() {

	});
```

Resulting variable `sWorker` is actually equal to the passed function from the second argument. Passed system name is stored in `@@name` property.

Name of the system has currently no use except filtering out duplicates when adding to the engine. In future releases when finite state machine will be implemented, name will become important.

Lets mark the returned function as **system initializer**. It's role is simply to initialize system logic upon invocation. Basically you could have system like the following code.

```js
	var sWorker = Scent.System.define('worker', function() {
		var components = require('./components');
		var nStructure = new Scent.Node([components.cBuilding, components.cFoundation]);
		nStructure.each(loopNode);
	});

	var loopNode = function(node) {
		// Worker can "build" the structure by adding more components to entity
	};
```

You might be wondering now what's the purpose of this. Why you would need to wrap the function by the System constructor? Well this is tightly coupled with the Engine implementation and it will make sense once you read about it.