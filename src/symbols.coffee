'use strict'

{Symbol} = require 'es6'

exports.bName = Symbol 'name of the object'
exports.bType = Symbol 'type of the object'

exports.bDispose = Symbol 'method to dispose object'
exports.bRelease = Symbol 'method to release disposed object'

exports.bChanged = Symbol 'timestamp of last change'
exports.bDisposing = Symbol 'timestamp of the object disposal'

exports.bEntity = Symbol 'reference to entity instance'

exports.Symbol = Symbol

# DEPRECATED
exports.bIdentity = Symbol 'identifier of the object'
exports.bFields = Symbol 'fields defined for the component'
exports.bDefinition = Symbol 'definition of the component'
