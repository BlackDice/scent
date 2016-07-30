log = (require 'debug') 'scent:system'
isFunction = require 'lodash/isFunction'
isString = require 'lodash/isString'

symbols = require './symbols'

hasWarned = false

exports.define = (name, initializer) ->

	unless hasWarned
		hasWarned = true
		log('''
			WARNING: Using System.define is deprecated and will be removed in next major version.
			Use plain function as initializer, optionally named.
		''')

	unless isString name
		throw new TypeError 'expected name for system'

	unless isFunction initializer
		throw new TypeError 'expected function as system initializer'

	initializer[ symbols.bName ] = name

	return Object.freeze initializer
