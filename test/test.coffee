# build time tests for wikigenesis plugin
# see http://mochajs.org/

wikigenesis = require '../client/wikigenesis'
expect = require 'expect.js'

describe 'wikigenesis plugin', ->

  describe 'expand', ->

    it 'can make itallic', ->
      result = wikigenesis.expand 'hello *world*'
      expect(result).to.be 'hello <i>world</i>'
