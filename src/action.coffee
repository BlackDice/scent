'use strict'

log = (require 'debug') 'scent:action'
_ = require 'lodash'
fast = require 'fast.js'

{Symbol} = require 'es6'
bData = Symbol 'internal data of the action type'

symbols = require './symbols'
Entity = require './entity'

Action = (name) ->
	unless _.isString name
		throw new TypeError 'missing name of the action type'

	actionType = Object.create Action.prototype
	actionType[ symbols.bName ] = name
	actionType[ bData ] = {}

	return Object.freeze actionType

Action.prototype = Object.create Function.prototype

Action::trigger = (entity) ->
	unless entity and entity instanceof Entity
		throw new TypeError 'expected entity for the trigger call'

	action = poolAction()
	action.entity = entity
	action.time = Date.now()

	if arguments.length > 1 and _.isPlainObject dataArg = arguments[1]
		action.get = (prop) ->
			return dataArg[prop]

	for val,i in arguments when i > 0
		action.push val

	data = this[ bData ]
	if data.frozen
		data.buffer = poolList() unless data.buffer
		target = data.buffer
	else
		data.list = poolList() unless data.list
		target = data.list

	target.push action
	return

Action::each = (iterator) ->
	unless iterator and _.isFunction iterator
		throw new TypeError 'expected iterator function for the each call'

	data = this[ bData ]
	data.frozen = yes

	return unless data.list?.length

	for action in data.list
		iterator.call iterator, action

	return

Action::finish = ->
	data = this[ bData ]
	if data.list
		for action in data.list
			action.length = 0
			poolAction action
		data.list.length = 0
		poolList data.list
		data.list = null

	data.list = data.buffer
	return

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

module.exports = Object.freeze Action