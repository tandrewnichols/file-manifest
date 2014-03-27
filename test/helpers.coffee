_ = require('underscore')
global.sinon = require('sinon')
global.expect = require('indeed').expect

global.proxyquire = require 'proxyquire'

_.mixin require('underscore.string')
global._ = _

global.spyObj = (fns...) ->
  _(fns).reduce (obj, fn) ->
    obj[fn] = sinon.stub()
    obj
  , {}
