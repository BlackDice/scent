global = do Function('return this')
global.IN_TEST = 'test'

global.Scent = require '../lib/scent.js'

require './index'