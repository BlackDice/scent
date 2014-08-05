log = (require 'debug') 'scent:node'
_  = require 'lodash'
fast = require 'fast.js'

require 'es6-shim'
nodeMapByHash = new Map

symbols = require './symbols'
{Symbol, sDispose, sType} = symbols
{sNext, sPrev} = symbols
sData = Symbol 'data for the frozen note type'
sList = Symbol 'list of components required by node'
sHead = Symbol 'reference to start of the list'
sTail = Symbol 'reference to end of the list'

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
	return nodeList if nodeList = nodeMapByHash.get hash
	
	# Create actual node list
	nodeList = Object.create NodeList, NodeListProps
	nodeList[ sList ] = componentTypes

	# Internal storage for writable data (nodeList is frozen)
	nodeList[ sData ] = nodeListData = Object.create null
	nodeListData[ sHead ] = null
	nodeListData[ sTail ] = null

	nodeMapByHash.set hash, nodeList
	Object.freeze nodeList
	return nodeList

NodeList =
	addEntity: ->
		entity = validateEntity arguments[0]
		nodeItem = Object.create null

		for componentType in this[ sList ]
			return unless component = entity.get componentType
			nodeItem[componentType[ symbols.sName ]] = component

		# Loop passed through, node item can be added
		nodeItem[ symbols.sEntity ] = entity
		addNodeItem this, nodeItem
		return

	updateEntity: ->
		entity = validateEntity arguments[0]
	removeEntity: ->
		entity = validateEntity arguments[0]
	each: ->

NodeListProps = Object.create null
NodeListProps['head'] =
	enumerable: yes
	get: -> this[ sData ][ sHead ]

NodeListProps['tail'] =
	enumerable: yes
	get: -> this[ sData ][ sTail ]

addNodeItem = (nodeList, nodeItem) ->
	nodeItem[ sNext ] = null
	nodeItem[ sPrev ] = null

	nodeListData = nodeList[ sData ]
	unless nodeListData[ sHead ]
		nodeListData[ sHead ] = nodeListData[ sTail ] = nodeItem
	else
		# Current last item points to added item
		nodeListData[ sTail ][ sNext ] = nodeItem
		# Added item points to the current tail
		nodeItem[ sPrev ] = nodeListData[ sTail ]
		# Tail point to added item
		nodeListData[ sTail ] = nodeItem

	Object.seal nodeItem

hashComponent = (result, componentType) ->
	result *= componentType[ symbols.sComponentNumber ]

validateEntity = (entity) ->
	unless entity and _.isFunction(entity.get)
		throw new TypeError 'invalid entity for node'
	return entity

validateComponentType = (componentType) ->
	return false unless componentType
	unless _.isFunction(componentType) and componentType[ symbols.sComponentNumber ]
		throw new TypeError 'invalid component for node'
	return true
