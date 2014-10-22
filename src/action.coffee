'use strict'

log = (require 'debug') 'scent:action'
_ = require 'lodash'
fast = require 'fast.js'

{Symbol} = require 'es6'
bData = Symbol 'internal data of the action type'

symbols = require './symbols'
Entity = require './entity'

ActionType = (identifier) ->
	unless identifier?
		throw new TypeError 'expected identifier of an action type'

	if this instanceof ActionType
		actionType = this
	else
		actionType = Object.create ActionType.prototype

	actionType[ symbols.bName ] = identifier
	actionType[ bData ] = {}

	return Object.freeze actionType

ActionType::trigger = (entity) ->
	action = poolAction()
	action.time = Date.now()

	if entity instanceof Entity
		argIndex = 1
		action.entity = entity
	else
		argIndex = 0
		action.entity = null

	if arguments.length > argIndex and _.isPlainObject dataArg = arguments[argIndex]
		action.get = (prop) ->
			return dataArg[prop]

	for val,i in arguments when i >= argIndex
		action.push val

	data = this[ bData ]
	if data.buffer
		target = data.buffer
	else
		data.list ?= poolList()
		target = data.list

	target.push action
	return

ActionType::each = (iterator) ->
	unless iterator and _.isFunction iterator
		throw new TypeError 'expected iterator function for the each call'

	data = this[ bData ]
	data.buffer ?= poolList()

	return unless data.list?.length

	for action in data.list
		iterator.call iterator, action

	return

ActionType::finish = ->
	data = this[ bData ]
	if data.list
		for action in data.list
			action.length = 0
			poolAction action
		data.list.length = 0
		poolList data.list
		data.list = null

	data.list = data.buffer
	data.buffer = null
	return

ActionType::toString = ->
	"ActionType #{this[ symbols.bName ]}"

listPool = []
poolList = (add) ->
	return listPool.push add if add
	return [] unless listPool.length
	return listPool.pop()

actionPool = []
poolAction = (add) ->
	return actionPool.push add if add
	return [] unless actionPool.length
	return actionPool.pop()

module.exports = Object.freeze ActionType