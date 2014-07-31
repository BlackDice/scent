chai = chai or require 'chai'

module and module.exports = 
	chai: chai
	expect: chai.expect
	sinon: require 'sinon'

chai.use require 'sinon-chai'
chai.use require 'chai-as-promised'