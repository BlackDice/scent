'use strict'

log = (require 'debug') 'scent:action'
isFunction = require 'lodash/isFunction'
fast = require 'fast.js'

{Symbol} = require 'es6'
bData = Symbol 'internal data of the action type'
bPool = Symbol 'pool of actions for this type'

symbols = require './symbols'
Entity = require './entity'

ActionType = (name) ->
	unless name?
		throw new TypeError 'expected name of an action type'

	if this instanceof ActionType
		actionType = this
	else
		actionType = Object.create ActionType.prototype

	actionType[ symbols.bName ] = name
	actionType[ bData ] = {}
	actionType[ bPool ] = []

	return actionType

Action = (@type, @data, @meta) ->

Action.prototype = Object.create Array.prototype
Action::time = 0
Action::type = null
Action::data = null
Action::meta = null
Action::get = (prop) ->
	this.data?[prop]
Action::set = (prop, val) ->
	this.data ?= {}
	this.data[prop] = val
	return this

ActionType::trigger = (data, meta) ->
	action = poolAction.call this
	action.time = Date.now()
	action.data = data
	action.meta = meta

	data = this[ bData ]
	if data.buffer
		data.buffer.push action
	else
		data.list ?= poolList()
		data.list.push action

	return action

ActionType::each = (iterator, ctx) ->
	unless iterator and isFunction iterator
		throw new TypeError 'expected iterator function for the each call'

	data = this[ bData ]
	# By setting buffer, the trigger method
	# stores any further action in this
	data.buffer ?= poolList()

	return unless data.list?.length

	fn = if ctx
		each$withContext
	else
		each$noContext

	for action in data.list
		fn iterator, action, ctx

	return

each$noContext = (fn, action) ->
    fn action

each$withContext = (fn, action, ctx) ->
    fn.call ctx, action

ActionType::finish = ->
	data = this[ bData ]
	if data.list
		for action in data.list
			action.data = null
			action.meta = null
			poolAction.call this, action

		data.list.length = 0
		poolList data.list
		data.list = null

	data.list = data.buffer
	data.buffer = null
	return

Object.defineProperties ActionType.prototype,
	'size':
		enumerable: yes
		get: ->
			return this[ bData ].list?.length or 0

ActionType::toString = ->
	"ActionType #{this[ symbols.bName ]}"

listPool = []
poolList = (add) ->
	return listPool.push add if add
	return [] unless listPool.length
	return listPool.pop()

poolAction = (add) ->
	pool = this[ bPool ]
	return pool.push add if add
	return new Action(this) unless pool.length
	return pool.pop()

module.exports = Object.freeze ActionType