isFunction = require 'lodash/lang/isFunction'
isString = require 'lodash/lang/isString'

symbols = require './symbols'

exports.define = (name, initializer) ->

	unless isString name
		throw new TypeError 'expected name for system'

	unless isFunction initializer
		throw new TypeError 'expected function as system initializer'

	initializer[ symbols.bName ] = name

	return Object.freeze initializer