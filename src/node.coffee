'use strict'

log = (require 'debug') 'scent:node'
_  = require 'lodash'
fast = require 'fast.js'

{Symbol, Map} = require './es6-support'

Lill = require 'lill'

symbols = require './symbols'
{bDispose, bType} = symbols
bList = Symbol 'list of components required by node'
bPool = Symbol 'pool of disposed nodes ready to use'

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
	nodeList = Object.create NodeList, NodeListProps
	nodeList[ bList ] = componentTypes
	nodeList[ bPool ] = []

	Lill.attach nodeList

	storageMap.set hash, nodeList if storageMap
	Object.freeze nodeList
	return nodeList

NodeList =
	addEntity: ->
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

		return this

	updateEntity: ->
		entity = validateEntity arguments[0]
		map = entity[ symbols.bNodes ]

		return this.addEntity entity unless nodeItem = map.get this

		for componentType in this[ bList ]
			unless component = entity.get componentType
				return this.removeEntity entity
			nodeItem[componentType[ symbols.bName ]] = component

		return this

	removeEntity: ->
		entity = validateEntity arguments[0]
		map = entity[ symbols.bNodes ]
		if nodeItem = map.get this
			Lill.remove this, nodeItem
			map.delete this
			nodeItem[ symbols.bEntity ] = null
			this[ bPool ].push nodeItem

		return this

	each: (fn, ctx) -> Lill.each this, fn, ctx

NodeListProps = Object.create null
NodeListProps['head'] =
	enumerable: yes
	get: -> Lill.getHead this

NodeListProps['tail'] =
	enumerable: yes
	get: -> Lill.getTail this

NodeListProps['size'] =
	enumerable: yes
	get: -> Lill.getSize this

hashComponent = (result, componentType) ->
	result *= componentType[ symbols.bNumber ]

validateEntity = (entity) ->
	unless entity and _.isFunction(entity.get)
		throw new TypeError 'invalid entity for node'
	return entity

validateComponentType = (componentType) ->
	return false unless componentType
	unless _.isFunction(componentType) and componentType[ symbols.bNumber ]
		throw new TypeError 'invalid component for node'
	return true

validateStorageMap = (storageMap) ->
	return false unless storageMap
	return true if storageMap instanceof Map
	return _.isFunction(storageMap.get) and _.isFunction(storageMap.set)

module.exports = Node