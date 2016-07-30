# System holds logic

System is basically just wrapper around the piece of code representing game mechanics. It can be really simple. Over complicated systems are much harder to read, test, maintain and debug. Keep that in mind when designing your systems.

## Defining the system

System doesn't need to be instantiated like other parts of the framework. System is defined by a plain function which is run once when Engine is started to actually setup its logic. 

```js
	function sWorker($engine) {
		var nStructure = new Scent.Node('building', 'foundating');
		
		$engine.onUpdate(function() {
			nStructure.each(loopNode);
		});

		function loopNode(node) {
			// Worker can "build" the structure by adding more components to entity
		};
	};
```

**Currently there is no way to remove the system from the Engine.**
