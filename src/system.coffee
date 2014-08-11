_ = require 'lodash'

symbols = require './symbols'

module.exports = (name, initializer) ->

	unless _.isString name
		throw new TypeError 'expected name for system'

	unless _.isFunction initializer
		throw new TypeError 'expected function as system initializer'

	initializer[ symbols.bName ] = name

	return Object.freeze initializer