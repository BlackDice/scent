'use strict'

log = (require 'debug') 'scent:node'
_  = require 'lodash'
fast = require 'fast.js'

{Symbol, Map} = require 'es6'

Lill = require 'lill'

symbols = require './symbols'
{bDispose, bType} = symbols
bList = Symbol 'list of components required by node'
bPool = Symbol 'pool of disposed nodes ready to use'
bData = Symbol 'internal data for node'

Node = (componentTypes, storageMap) ->

	# Wrap the value into array if none passed
	componentTypes = [componentTypes] unless _.isArray componentTypes

	# Filter out duplicates and invalid component types
	componentTypes = _(componentTypes).uniq().filter(validateComponentType).value()

	unless componentTypes.length
		throw new TypeError 'require at least one component for node'

	if storageMap and not validateStorageMap storageMap
		throw new TypeError 'valid storage map expected in second argument'

	# Calculate hash based on prime numbers
	hash = fast.reduce componentTypes, hashComponent, 1

	# Return existing node list
	return nodeList if storageMap and nodeList = storageMap.get hash

	# Create actual node list
	nodeList = new NodeList componentTypes

	Lill.attach nodeList

	storageMap.set hash, nodeList if storageMap
	Object.freeze nodeList
	return nodeList

NodeList = (componentTypes) ->
	this[ bList ] = componentTypes
	this[ bPool ] = []
	this[ bData ] = {}
	return this

NodeList::addEntity = ->
	entity = validateEntity arguments[0]
	map = entity[ symbols.bNodes ]

	return this if map.has this

	if (pool = this[ bPool ]).length
		nodeItem = pool.pop()
	else
		nodeItem = Object.create null
		nodeItem[ bType ] = this

	for componentType in this[ bList ]
		return this unless component = entity.get componentType
		nodeItem[componentType[ symbols.bName ]] = component

	# Store entity within node item
	nodeItem[ symbols.bEntity ] = entity

	# Store node item references
	map.set this, nodeItem
	Lill.add this, nodeItem

	if added = this[ bData ].added
		Lill.add added, nodeItem

	return this

NodeList::updateEntity = ->
	entity = validateEntity arguments[0]
	map = entity[ symbols.bNodes ]

	return this.addEntity entity unless nodeItem = map.get this

	for componentType in this[ bList ]
		unless component = entity.get componentType
			return this.removeEntity entity
		nodeItem[componentType[ symbols.bName ]] = component

	return this

NodeList::removeEntity = ->
	entity = validateEntity arguments[0]
	map = entity[ symbols.bNodes ]
	if nodeItem = map.get this
		Lill.remove this, nodeItem
		map.delete this
		# If anything watches for removed nodes
		# the actual pooling is postpoed
		if removed = this[ bData ].removed
			Lill.add removed, nodeItem
		else
			poolNodeItem.call this, nodeItem

	return this

NodeList::each = (fn, ctx) -> Lill.each this, fn, ctx

NodeList::onAdded = (callback) ->
	unless _.isFunction callback
		throw new TypeError 'expected callback function for onNodeAdded call'

	{added} = this[ bData ]
	unless added
		this[ bData ].added = added = []
		Lill.attach added

	added.push callback
	return this

NodeList::onRemoved = (callback) ->
	unless _.isFunction callback
		throw new TypeError 'expected callback function for onNodeRemoved call'

	{removed} = this[ bData ]
	unless removed
		this[ bData ].removed = removed = []
		Lill.attach removed

	removed.push callback
	return this

NodeList::finish = ->
	data = this[ bData ]

	if (added = data.added) and Lill.getSize(added)
		for addedCb in added
			Lill.each added, addedCb
			Lill.clear added

	if (removed = data.removed) and Lill.getSize(removed)
		for removedCb in removed
			Lill.each removed, removedCb
		# Return removed nodes to pool
		Lill.each removed, poolNodeItem.bind this
		Lill.clear removed

	return this

Object.defineProperties NodeList.prototype,
	'head':
		enumerable: yes
		get: -> Lill.getHead this

	'tail':
		enumerable: yes
		get: -> Lill.getTail this

	'size':
		enumerable: yes
		get: -> Lill.getSize this

poolNodeItem = (nodeItem) ->
	nodeItem[ symbols.bEntity ] = null
	this[ bPool ].push nodeItem

hashComponent = (result, componentType) ->
	result *= componentType[ symbols.bIdentity ]

validateEntity = (entity) ->
	unless entity and _.isFunction(entity.get)
		throw new TypeError 'invalid entity for node'
	return entity

validateComponentType = (componentType) ->
	return false unless componentType
	unless _.isFunction(componentType) and componentType[ symbols.bIdentity ]
		throw new TypeError 'invalid component for node'
	return true

validateStorageMap = (storageMap) ->
	return false unless storageMap
	return true if storageMap instanceof Map
	return _.isFunction(storageMap.get) and _.isFunction(storageMap.set)

module.exports = Node