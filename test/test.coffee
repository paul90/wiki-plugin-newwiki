# build time tests for newwiki plugin
# see http://mochajs.org/

newwiki = require '../client/newwiki'
expect = require 'expect.js'

describe 'newwiki plugin', ->

  describe 'expand', ->

    it 'can make itallic', ->
      result = newwiki.expand 'hello *world*'
      expect(result).to.be 'hello <i>world</i>'
