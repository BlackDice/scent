'use strict'

log = (require 'debug') 'scent:node'
_  = require 'lodash'
fast = require 'fast.js'

require 'es6-shim'
nodeListsByHash = new Map

Lill = require 'lill'

symbols = require './symbols'
{Symbol, sDispose, sType} = symbols
{sNext, sPrev} = symbols
sList = Symbol 'list of components required by node'
sPool = Symbol 'pool of disposed nodes ready to use'

module.exports = Node = (componentTypes) ->

	# Wrap the value into array if none passed
	componentTypes = [componentTypes] unless _.isArray componentTypes

	# Filter out duplicates and invalid component types
	componentTypes = _(componentTypes).uniq().filter(validateComponentType).value()

	unless componentTypes.length
		throw new TypeError 'require at least one component for node'

	# Calculate hash based on prime numbers
	hash = fast.reduce componentTypes, hashComponent, 1

	# Return existing node list
	return nodeList if nodeList = nodeListsByHash.get hash
	
	# Create actual node list
	nodeList = Object.create NodeList, NodeListProps
	nodeList[ sList ] = componentTypes
	nodeList[ sPool ] = []

	Lill.attach nodeList

	nodeListsByHash.set hash, nodeList
	Object.freeze nodeList
	return nodeList

NodeList =
	addEntity: ->
		entity = validateEntity arguments[0]
		map = entity[ symbols.sNodes ]

		return this if map.has this

		if (pool = this[ sPool ]).length
			nodeItem = pool.pop()
		else
			nodeItem = Object.create null
			nodeItem[ sType ] = this

		for componentType in this[ sList ]
			return this unless component = entity.get componentType
			nodeItem[componentType[ symbols.sName ]] = component

		# Store entity within node item
		nodeItem[ symbols.sEntity ] = entity

		# Store node item references
		map.set this, nodeItem
		Lill.add this, nodeItem

		return this

	updateEntity: ->
		entity = validateEntity arguments[0]
		map = entity[ symbols.sNodes ]

		return this.addEntity entity unless nodeItem = map.get this

		for componentType in this[ sList ]
			unless component = entity.get componentType
				return this.removeEntity entity
			nodeItem[componentType[ symbols.sName ]] = component

		return this

	removeEntity: ->
		entity = validateEntity arguments[0]
		map = entity[ symbols.sNodes ]
		if nodeItem = map.get this
			Lill.remove this, nodeItem
			map.delete this
			nodeItem[ symbols.sEntity ] = null
			this[ sPool ].push nodeItem

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
	result *= componentType[ symbols.sNumber ]

validateEntity = (entity) ->
	unless entity and _.isFunction(entity.get)
		throw new TypeError 'invalid entity for node'
	return entity

validateComponentType = (componentType) ->
	return false unless componentType
	unless _.isFunction(componentType) and componentType[ symbols.sNumber ]
		throw new TypeError 'invalid component for node'
	return true
