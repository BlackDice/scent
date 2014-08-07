'use strict'

exports.Symbol = Symbol = require 'es6-symbol'

exports.sName = Symbol 'various names for the objects'
exports.sType = Symbol 'contains type of the object'
exports.sNumber = Symbol 'numeric identifier of the object'

exports.sDispose = Symbol 'method name for disposing objects'

exports.sEntity = Symbol 'represent entity reference on the object'
exports.sNext = Symbol 'next item in the list'
exports.sPrev = Symbol 'previous item in the list'
exports.sNodes = Symbol 'nodes that owns current entity'