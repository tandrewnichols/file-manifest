sinon = require 'sinon'

describe 'loaders', ->
  Given -> @readutf =
    readFile: sinon.stub()
    readFileSync: sinon.stub()
  Given -> @subject = require('proxyquire').noCallThru() '../../lib/loaders',
    file: 'contents'
    readutf: @readutf

  describe '.require', ->
    context 'with a callback', ->
      Given -> @cb = sinon.stub()
      When -> @subject.require 'file', @cb
      Then -> @cb.should.be.calledWith null, 'contents'

    context 'with no callback', ->
      Then -> @subject.require('file').should.equal 'contents'

  describe '.readFile', ->
    context 'with a callback', ->
      Given -> @cb = sinon.stub()
      Given -> @readutf.readFile.withArgs('file', @cb).callsArgWith 1, 'blah'
      When -> @subject.readFile 'file', @cb
      Then -> @cb.should.be.calledWith 'blah'

    context 'with no callback', ->
      Given -> @readutf.readFileSync.withArgs('file').returns 'blah'
      Then -> @subject.readFile('file').should.equal 'blah'
