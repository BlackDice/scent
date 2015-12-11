# SCENT: A System-Component-Entity framework

*Make a great game with fresh scent. It smells really good !*

[![Build Status](https://travis-ci.org/BlackDice/scent.svg)](https://travis-ci.org/BlackDice/scent)[![Dependencies status](https://david-dm.org/BlackDice/scent/status.svg)](https://david-dm.org/BlackDice/scent#info=dependencies)[![devDependency Status](https://david-dm.org/BlackDice/scent/dev-status.svg)](https://david-dm.org/BlackDice/scent#info=devDependencies)

[![NPM](https://nodei.co/npm/scent.png)](https://nodei.co/npm/scent/)

Scent is framework heavily based on the [Ash framework](http://www.ashframework.org/) and rewritten for the purpose of multi-player games. Basic idea is very similar however coding style is quite different. Thanks to the environments like NodeJS, you can use Scent on the game server too and share most of code with game client.

Main idea of this approach is [composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance). You are no longer creating objects with all of its properties and method in one big messy blob. Instead you are composing entities from small pieces called components. That way you can create various combinations without duplicating any code.

## Disclaimer

Please note that this is far from complete solution of *how to make the game*. This is only small ingredient of the whole cake that needs to be used in much more robust environment to handle all game requirements. Possibly it is something that most of games have in common no matter of genre.

### In development

Framework is being actively used in development of our own game. It can be improved and changed over time as our need arise. Check out the [contributing file](contributing.md) if you want to help with something.

There is no Roadmap for the framework yet, it mostly depends on ours needs in the game. Essential stuff is already in place and working quite well.

## EcmaScript 6 support

Framework is using some of the features as defined by EcmaScript 6 draft. Since the implementation in current environments is not really production ready, we are using shims.

### Symbol usage

To avoid collisions in some variable names and also to store truly private states, framework is using the **Symbol** structure. All public symbols are exported in Symbols property of Scent entry point (see below).

Acknowledged notation exists for the symbols, it uses `@@` as prefix. Anytime when we are using this prefix be aware you have to use the symbol of that name from mentioned export.

## Type prefix

There is notation for variables holding known types defined by this framework. Actual variable name is prefixed by single letter denoting the type. First letter of the original variable should be uppercased. We recommend using this notation while using the framework to make clear idea of what is the variable holding.

	cWeapon      component type
	eCharacter   entity instance
	nStructure   node type
	aMove        action type
	bName        symbol reference

## Installation and basic usage

Framework is available from NPM.

```bash
	npm install -S scent
```

We are using CommonJS modules. You can use these in NodeJS directly or in browser with the help of Browserify. Module exports simply an object referencing all parts of the framework.

Following is small example how simply you can create game mechanics to close door based on their material. In the real game it would be much more complex, but it should suffice for now.

```js
	var Scent = require('scent');

	var cDoor = new Scent.Component('door', 'open material');

	var engine = new Scent.Engine();
	engine.addSystem(Scent.System.define('closeDoor', function() {
		var nDoor = engine.getNodeType([cDoor]);

		engine.onUpdate(function(timestamp) {
			nDoor.each(loopDoorNode, timestamp);
		});

		var closingTime = {
			'wood': 200,
			'metal': 300,
			'stone': 500
		};

		var loopDoorNode = function(node, timestamp) {
			if (node.door.open >= timestamp + closingTime[node.door.material]) {
				node.door.open = false;
			}
		};
	});

	engine.start();

	var door = new cDoor()
	door.material = 'wood';
	var eDoor = engine.buildEntity([door]);

	engine.onAction('doorOpen', function(action) {
		var eDoor = action.data;
		eDoor.get(cDoor).open = Date.now();
	});

	engine.triggerAction('doorOpen', eDoor);

	// updates are supposed to be executed in your game loop.
	engine.update(Date.now() + 300);
```

It might look confusing at this point, especially if you don't know much about entity driven approach. Hence if you are interested, dive right in. We recommend reading further in this order:

 * [Component](docs/component.md) ... is smallest part the design. It is data storage unit that is meant to be added to or removed from the entity.
 * [Entity](docs/entity.md) ... is any game object. It is composed of components designating the purpose of entity that way.
 * [Node](docs/node.md) ... is small subset of components owned by single entity and simplifies work of the systems.
 * [Action](docs/action.md) ... is container for any game events that might have happened and needs some processing.
 * [System](docs/system.md) ... is a wrapper for your game logic.

These parts are base building blocks, but they are quite useless on its own. Once you have some apprehension of the role of each of them, you can start reading about [The Engine](docs/engine.md) which ties everything together.

## Error handling

There are some checks for correct type or format of arguments that can throw error. Basically you don't need to handle these errors because they are meant to alert you about doing something seriously wrong mostly in the setup phase.

There is minimum of runtime errors (except unexpected ones). Instead the [debug](https://www.npmjs.org/package/debug) module is used with prefix of "scent:" that warns you about runtime issues.

## Tests

To have a look at tests outcome, you have to install node dependencies first (using `npm install`) and then you can simply run `npm test` to see the test outcome.

For development we are using amazing Test'em tool. Just install it globally (`npm install -g testem`) and then run in this directory (`testem`). Tests will run in Node environment by default and you can connect with any browser to see how the framework behaves in there.

## License

The MIT License (MIT)
Copyright © 2014 Black Dice Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
