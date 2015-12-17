'use strict'

log = (require 'debug') 'scent:node'

_  = require 'lodash'
fast = require 'fast.js'
Lill = require 'lill'

{Symbol, Map} = require 'es6'
Component = require './component'

{bType} = symbols = require './symbols'
bData = Symbol 'internal data for the node type'

# Constructor function to create node type with given set
# of component types. Used internally.
NodeType = (componentTypes, componentProvider) ->

	unless this instanceof NodeType
		return new NodeType componentTypes, componentProvider

	validComponentTypes = NodeType.validateComponentTypes(
		componentTypes, componentProvider
	)

	unless validComponentTypes?.length
		throw new TypeError 'node type requires at least one component type'

	this[ bData ] = {
		types: validComponentTypes
		item: createNodeItem(this, validComponentTypes)
		pool: fast.bind poolNodeItem, null, []
		ref: Symbol 'node('+validComponentTypes.map(mapComponentName).join(',')+')'
		added: false
		removed: false
	}

	return Lill.attach this

# Method checks if entity fulfills component types constraints
# defined for node type.
NodeType::entityFits = (entity) ->
	return false if entity[ symbols.bDisposing ]
	for componentType in this[ bData ]['types']
		return false unless entity.has componentType
	return true

# Method is used to add new entity to the list. It rejects
# entity that is already on the list or if required components
# are missing.
NodeType::addEntity = ->
	data = this[ bData ]
	entity = validateEntity arguments[0]

	# entity already watched by this node type or
	# it doesn't fit in here
	if entity[ data.ref ] or not @entityFits entity
		return this

	# grab node item from pool or create new one
	unless nodeItem = data.pool()
		nodeItem = new data.item

	# mutual references
	nodeItem[ symbols.bEntity ] = entity
	entity[ data.ref ] = nodeItem

	# store node item to the node type
	Lill.add this, nodeItem

	# if there are handlers for onAdded, remember node item
	Lill.add added, nodeItem if added = data.added

	return this

# Method to remove entity from the node type if it no longer
# fits in the node type constrains.
NodeType::removeEntity = ->
	data = this[ bData ]
	entity = validateEntity arguments[0]

	return this unless nodeItem = entity[ data.ref ]
	return this if @entityFits entity

	Lill.remove this, nodeItem
	delete entity[ data.ref ]

	# if anything watches for removed nodes the actual pooling is postponed
	if removed = data.removed
		Lill.add removed, nodeItem
	else
		data.pool(nodeItem)

	return this

# For entity that is not part of the node type, it will be
# checked against component type constrains and added if valid.
# Otherwise entity is removed from node type forcefully.
NodeType::updateEntity = ->
	data = this[ bData ]
	entity = validateEntity arguments[0]

	unless entity[ data.ref ]
		return this.addEntity entity
	else
		return this.removeEntity entity

	return this

# Wrapper method for looping over node items.
NodeType::each = (fn) ->
	if arguments.length <= 1
		Lill.each this, fn
		return this

	args = Array.prototype.slice.call arguments, 1
	Lill.each this, Node$each = (node) ->
		fn(node, args...)

	return this

# Wrapper method for finding node item.
NodeType::find = (predicate) ->
	if arguments.length <= 1
		return Lill.find this, predicate

	args = Array.prototype.slice.call arguments, 1
	return Lill.find this, Node$find = (node) ->
		predicate(node, args...)

# Allow to register callback function that will be called
# whenever new entity is added to the node type. Callbacks
# will be executed when finish() method is invoked.
NodeType::onAdded = (callback) ->
	unless _.isFunction callback
		throw new TypeError 'expected callback function for onNodeAdded call'

	{added} = data = this[ bData ]
	unless added
		data.added = added = []
		Lill.attach added

	added.push callback
	return this

# Similar to onAdded, but invokes callbacks for each removed
# entity when finish() method is invoked.
NodeType::onRemoved = (callback) ->
	unless _.isFunction callback
		throw new TypeError 'expected callback function for onNodeRemoved call'

	{removed} = data = this[ bData ]
	unless removed
		data.removed = removed = []
		Lill.attach removed

	removed.push callback
	return this

# Used to invoke registered onAdded and onRemoved callbacks.
NodeType::finish = ->
	data = this[ bData ]

	if (added = data.added) and Lill.getSize(added)
		for addedCb in added
			Lill.each added, addedCb
		Lill.clear added

	if (removed = data.removed) and Lill.getSize(removed)
		for removedCb in removed
			Lill.each removed, removedCb
		# return removed nodes to pool
		Lill.each removed, data.pool
		Lill.clear removed

	return this

# Some convenient properties from Lill.
Object.defineProperties NodeType.prototype,
	'head':
		enumerable: yes
		get: -> Lill.getHead this

	'tail':
		enumerable: yes
		get: -> Lill.getTail this

	'size':
		enumerable: yes
		get: -> Lill.getSize this

	'types':
		enumerable: yes
		get: -> this[ bData ]['types']

## NODEITEM

# Creates node item constructor function having properties
# for component types attached to prototype.
createNodeItem = (nodeType, componentTypes) ->

	NodeItem = ->
	NodeItem.prototype = new BaseNodeItem nodeType

	for componentType in componentTypes
		defineComponentProperty NodeItem, componentType

	return NodeItem

# Define property with name of component type and getter that
# returns current component instance from entity.
defineComponentProperty = (nodeItemConstructor, componentType) ->
	Object.defineProperty(
		nodeItemConstructor.prototype
		componentType.typeName
		{
			enumerable: yes
			get: -> this[ symbols.bEntity ].get(componentType, true)
		}
	)

## BASENODEITEM

BaseNodeItem = (nodeType) ->
	this[ symbols.bType ] = nodeType
	return this

BaseNodeItem::[ symbols.bType ] = null
BaseNodeItem::[ symbols.bEntity ] = null

Object.defineProperty BaseNodeItem.prototype, 'entityRef', {
	enumerable: yes
	get: -> this[ symbols.bEntity ]
}

## INSPECTION

BaseNodeItem::inspect = ->
	result = {
		"--nodeType": this[ symbols.bType ].inspect(yes)
		"--entity": this[ symbols.bEntity ].inspect()
	}

	for componentType in this[ symbols.bType ][ bData ]['types']
		result[componentType.typeName] = this[componentType.typeName]?.inspect()

	return result

NodeType::inspect = (metaOnly) ->
	data = this[ bData ]
	result = {
		"--nodeSpec": data['types'].map(mapComponentName).join(',')
		"--listSize": this.size
	}
	return result if metaOnly is yes

	toResult = (label, source) ->
		return unless source and Lill.getSize(source)
		target = result[label] = []
		Lill.each source, (item) ->
			target.push item.inspect()

	toResult 'all', this
	toResult 'added', data.added
	toResult 'removed', data.removed

	return result

## UTILITY FUNCTIONS

mapComponentName = (componentType) ->
	return componentType.typeName

poolNodeItem = (pool, nodeItem) ->
	unless nodeItem and pool.length
		return pool.pop()
	nodeItem[ symbols.bEntity ] = null
	pool.push nodeItem

validateEntity = (entity) ->
	unless entity and _.isFunction(entity.get)
		throw new TypeError 'invalid entity for node type'
	return entity

bValidated = Symbol 'validated node type component list'

NodeType.validateComponentTypes = (types, componentProvider) ->

	unless _.isObject types
		return new Array(0)

	if types[bValidated]
		return types

	failed = (result) ->
		result.length -= 1
		return result

	lastIdx = 0

	validateType = (result, componentType) ->
		unless componentType
			return failed(result)

		unless componentType instanceof Component
			if componentProvider
				unless providedType = componentProvider(componentType)
					log 'invalid component type used for node:', componentType
					return failed(result)
				componentType = providedType
			else
				return failed(result)

		if result.length and ~result.indexOf(componentType)
			log 'trying to use duplicate component type for node:' + componentType.typeDefinition
			return failed(result)

		result[lastIdx] = componentType
		lastIdx += 1
		return result

	if _.isArray types
		validTypes = fast.reduce types, validateType, new Array(types.length)
	else
		validTypes = validateType new Array(1), types

	# created array with component types is marked with symbol
	# to avoid double validation when using getNodeType from
	# the Engine
	validTypes[bValidated] = true
	return validTypes

module.exports = Object.freeze NodeType