_ = require('underscore')
global.sinon = require('sinon')
global.expect = require('indeed').expect
sandboxedModule = require('sandboxed-module')

global.sandbox = (path, requires, globals) ->
  sandboxedModule.require("./../#{path}", {requires, globals})

_.mixin
  fix: (obj) ->
    JSON.parse(JSON.stringify(obj))

global.spyObj = (fns...) ->
  _(fns).reduce (obj, fn) ->
    obj[fn] = sinon.stub()
    obj
  , {}
