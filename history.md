0.9.0 [2016-07-30]

 * register of components so they can be used more easily
 * deprecate System.define in favor of named plain functions
 * separate methods for creating and adding entity to the engine
 * check for the engine to be started before running the update
 * dropped support for Node < 4.0
 * publish ES6 compatible source files for custom building

0.8.2 [2015-05-06]

 * added `size` property to action type
 * updated action processing to allow nested triggering

0.8.1 [2015-30-05]

 * fixed Engine.getNodeType to add matching entities that already exists

0.8.0 [2015-21-05]
 
 * added NodeType:find() method
 * updated dependencies

0.7.4 [2015-18-05]
 
 * using standard method of prototyping for the Engine

0.7.3 [2015-10-04]

 * Fixing onAction examples in readme. #7
 * run all Node.onAdded callbacks. #6

0.7.2 [2015-28-01]
 
 * Allow triggering actions with no handlers? #3

0.7.1 [2014-07-12]

 * Engine.addSystem doesn't require use of System.define() anymore. Any function can be passed in while setting @@name property automatically to anything sensible.
