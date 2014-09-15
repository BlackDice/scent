/*
* The MIT License (MIT)
* Copyright © 2014 Daniel K. (FredyC)
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* 
* Version: 0.2.0
*/
'use strict';
var Symbol;

Symbol = require('es6').Symbol;

exports.bName = Symbol('name of the object');

exports.bType = Symbol('type of the object');

exports.bDispose = Symbol('method to dispose object');

exports.bChanged = Symbol('timestamp of last change');

exports.bIdentity = Symbol('identifier of the object');

exports.bFields = Symbol('fields defined for the component');

exports.bNodes = Symbol('nodes that owns entity');

exports.bEntity = Symbol('reference to entity instance');

exports.Symbol = Symbol;
