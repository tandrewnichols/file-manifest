sinon = require 'sinon'

describe 'reducers', ->
  Given -> @subject = require '../../lib/reducers'

  describe '._getVal', ->
    Given -> @context =
      load: sinon.stub()
    Given -> @assign = sinon.stub()
    Given -> @next = sinon.stub()
    Given -> @assign.withArgs('val').returns 'assigned val'

    context 'next is not a function', ->
      Given -> @context.load.withArgs('file').returns 'val'
      Then -> @subject._getVal.call(@context, 'file', null, @assign).should.equal 'assigned val'

    context 'next is a function', ->
      Given -> @context.load.withArgs('file', sinon.match.func).callsArgWith 1, null, 'val'
      When -> @subject._getVal.call @context, 'file', @next, @assign
      Then -> @next.should.be.calledWith null, 'assigned val'

  describe '.flat', ->
    afterEach -> @subject._getVal = @subject._getValBak
    Given -> @subject._getValBak = @subject._getVal
    Given -> @subject._getVal = (file, next, fn) -> fn 'val'
    Given -> @context =
      name: sinon.stub()
    Given -> @context.name.withArgs('file').returns 'key'
    Then -> @subject.flat.call(@context, {}, 'file', 'next').should.eql key: 'val'

  describe '.nested', ->
    afterEach -> @subject._getVal = @subject._getValBak
    Given -> @subject._getValBak = @subject._getVal
    Given -> @subject._getVal = (file, next, fn) -> fn 'val'
    Given -> @file =
      relative: sinon.stub()
    Given -> @file.relative.withArgs(transform: 'dot').returns 'foo.bar'
    Then -> @subject.nested({}, @file, 'next').should.eql
      foo:
        bar: 'val'

  describe '.list', ->
    afterEach -> @subject._getVal = @subject._getValBak
    Given -> @subject._getValBak = @subject._getVal
    Given -> @subject._getVal = (file, next, fn) -> fn 'val'
    Given -> @context =
      name: sinon.stub()
    Given -> @context.name.withArgs('file').returns 'key'
    Then -> @subject.list.call(@context, [], 'file', 'next').should.eql ['val']

  describe '.objectList', ->
    afterEach -> @subject._getVal = @subject._getValBak
    Given -> @subject._getValBak = @subject._getVal
    Given -> @subject._getVal = (file, next, fn) -> fn 'val'
    Given -> @file =
      relative: sinon.stub()
    Given -> @file.relative.withArgs(ext: false).returns 'key'
    Then -> @subject.objectList([], @file, 'next').should.eql [
      name: 'key'
      contents: 'val'
    ]
