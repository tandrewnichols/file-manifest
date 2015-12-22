sinon = require 'sinon'

describe 'file-manifest', ->
  Given -> @subject = require '../../lib/file-manifest'

  describe '.generate', ->
    afterEach -> @subject.run.restore()
    afterEach -> @subject.load.restore()
    afterEach -> @subject.name.restore()
    afterEach -> @subject.standardizePath.restore()
    Given -> sinon.stub @subject, 'run'
    Given -> sinon.stub(@subject, 'load').returns 'load'
    Given -> sinon.stub(@subject, 'name').returns 'name'
    Given -> sinon.stub(@subject, 'standardizePath').returnsArg 0

    context 'no options', ->
      When -> @subject.generate 'dir'
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: undefined
        memo: {}
        load: 'load'
        name: 'name'

    context 'callback but no options', ->
      Given -> @cb = sinon.stub()
      When -> @subject.generate 'dir', @cb
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: @cb
        memo: {}
        load: 'load'
        name: 'name'

    context 'with match as array', ->
      When -> @subject.generate 'dir',
        match: ['blah']
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: ['blah']
        callback: undefined
        memo: {}
        load: 'load'
        name: 'name'

    context 'with match as string', ->
      When -> @subject.generate 'dir',
        match: 'blah'
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: ['blah']
        callback: undefined
        memo: {}
        load: 'load'
        name: 'name'

    context 'with memo', ->
      When -> @subject.generate 'dir',
        memo: []
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: undefined
        memo: []
        load: 'load'
        name: 'name'

    context 'with load as a function', ->
      Given -> @load = sinon.stub()
      When -> @subject.generate 'dir',
        load: @load
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: undefined
        memo: {}
        load: @load
        name: 'name'

    context 'with load as a string', ->
      Given -> @subject.load.withArgs('custom').returns 'custom'
      When -> @subject.generate 'dir',
        load: 'custom'
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: undefined
        memo: {}
        load: 'custom'
        name: 'name'

    context 'with name as a function', ->
      Given -> @name = sinon.stub()
      When -> @subject.generate 'dir',
        name: @name
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: undefined
        memo: {}
        load: 'load'
        name: @name

    context 'with name as a string', ->
      Given -> @subject.name.withArgs('custom').returns 'custom'
      When -> @subject.generate 'dir',
        name: 'custom'
      Then -> @subject.run.should.be.calledWith
        dir: 'dir'
        match: undefined
        callback: undefined
        memo: {}
        load: 'load'
        name: 'custom'

  describe '.generateSync', ->
    afterEach -> @subject.generate.restore()
    Given -> sinon.stub @subject, 'generate'
    When -> @subject.generateSync 'dir', 'options'
    Then -> @subject.generate.should.be.calledWith 'dir', 'options'

  describe '.generatePromise', ->
    afterEach -> @subject.generate.restore()
    Given -> sinon.stub @subject, 'generate'

    context 'no error', ->
      Given -> @subject.generate.withArgs('dir', 'options', sinon.match.func).callsArgWithAsync 2, null, 'manifest'
      When (done) -> @subject.generatePromise('dir', 'options').then (@manifest) => done()
      Then -> @manifest.should.equal 'manifest'

    context 'with error', ->
      Given -> @subject.generate.withArgs('dir', 'options', sinon.match.func).callsArgWithAsync 2, 'err'
      When (done) -> @subject.generatePromise('dir', 'options').then ((@manifest) => done()), ((@err) => done())
      Then -> @err.should.equal 'err'

  describe '.generateEvent', ->
    afterEach -> @subject.generate.restore()
    Given -> sinon.stub @subject, 'generate'
    
    context 'no error', ->
      Given -> @subject.generate.withArgs('dir', 'options', sinon.match.func).callsArgWithAsync 2, null, 'manifest'
      When (done) -> @subject.generateEvent('dir', 'options').on 'manifest', (@manifest) => done()
      Then -> @manifest.should.equal 'manifest'

    context 'with error', ->
      Given -> @subject.generate.withArgs('dir', 'options', sinon.match.func).callsArgWithAsync 2, 'err'
      When (done) -> @subject.generateEvent('dir', 'options').on 'error', (@err) => done()
      Then -> @err.should.equal 'err'

  describe '.standardizePath', ->
    Given -> @stack = require('stack-trace')
    afterEach -> @stack.get.restore()
    Given -> sinon.stub @stack, 'get'

    context 'absolute path', ->
      When -> @dir = @subject.standardizePath '/foo/bar'
      Then -> @dir.should.equal '/foo/bar'

    context 'relative path', ->
      Given -> @stack.get.returns [
        getFileName: -> '/foo/banana.js'
      ]
      When -> @dir = @subject.standardizePath 'blah'
      Then -> @dir.should.equal '/foo/blah'

  describe '.run', ->
    Given -> @File = require('defiled')
    Given -> @pedestrian = require('pedestrian')
    afterEach -> @pedestrian.walk.restore()
    Given -> sinon.stub @pedestrian, 'walk'
    afterEach -> @subject.reduce.restore()
    Given -> sinon.stub @subject, 'reduce'

    context 'without a callback', ->
      Given -> @subject.reduce.returnsArg 0
      Given -> @pedestrian.walk.withArgs('dir', '').returns ['/foo/bar', '/foo/baz']
      When -> @subject.run
        dir: 'dir'
        memo: {}
      Then ->
        @subject.reduce.should.be.calledWith {}, sinon.match.has('_file', '/foo/bar')
        @subject.reduce.should.be.calledWith {}, sinon.match.has('_file', '/foo/baz')

    context 'with a callback', ->
      Given -> @cb = sinon.stub()
      Given -> @reduce = sinon.stub()
      Given -> @reduce.callsArgWith 2, null, {}
      Given -> @pedestrian.walk.withArgs('dir', '', sinon.match.func).callsArgWith 2, null, ['/foo/bar', '/foo/baz']
      When -> @subject.run
        dir: 'dir'
        memo: {}
        callback: @cb
        reduce: @reduce
      Then ->
        @reduce.should.be.calledWith {}, sinon.match.has('_file', '/foo/bar'), sinon.match.func
        @reduce.should.be.calledWith {}, sinon.match.has('_file', '/foo/baz'), sinon.match.func
        @cb.should.be.called

  describe '.reduce', ->
    afterEach -> @subject.load.restore()
    Given -> sinon.stub @subject, 'load'
    afterEach -> @subject.name.restore()
    Given -> sinon.stub(@subject, 'name').returns 'banana'
    
    context 'without a callback', ->
      Given -> @subject.load.withArgs('file').returns 'contents'
      When -> @manifest = @subject.reduce({}, 'file')
      Then -> @manifest.should.eql banana: 'contents'

    context 'with a callback', ->
      Given -> @cb = sinon.stub()
      Given -> @subject.load.withArgs('file', sinon.match.func).callsArgWith 1, null, 'contents'
      When -> @subject.reduce {}, 'file', @cb
      Then -> @cb.should.be.calledWith null, banana: 'contents'

  describe '.name', ->
    context 'transformer exists', ->
      Given -> @relative = sinon.stub()
      Given -> @relative.withArgs(transform: 'blah').returns 'transformed blah'
      When -> @namer = @subject.name 'blah'
      And -> @name = @namer
        relative: @relative
        transformers:
          blah: true
      Then -> @name.should.equal 'transformed blah'

    context 'transformer does not exist', ->
      Given -> @relative = sinon.stub()
      Given -> @relative.withArgs(transform: 'camel').returns 'transformed camel'
      When -> @namer = @subject.name 'blah'
      And -> @name = @namer
        relative: @relative
        transformers: {}
      Then -> @name.should.equal 'transformed camel'

  describe '.load', ->
    Given -> @loaders = require '../../lib/loaders'
    Given -> @loaders.banana = sinon.stub()
    Given -> @loaders.banana.withArgs('absolute', 'cb').returns 'loaded'
    afterEach -> @subject._getDefaultLoader.restore()
    Given -> sinon.stub @subject, '_getDefaultLoader'
    Given -> @abs = sinon.stub()
    Given -> @abs.returns 'absolute'

    context 'loader exists', ->
      When -> @loader = @subject.load 'banana'
      And -> @load = @loader
        abs: @abs
      , 'cb'
      Then -> @load.should.equal 'loaded'

    context 'loader does not exist', ->
      Given -> @subject._getDefaultLoader.withArgs({ abs: @abs }, 'cb').returns 'banana'
      When -> @loader = @subject.load 'apple'
      And -> @load = @loader
        abs: @abs
      , 'cb'
      Then -> @load.should.equal 'loaded'

  describe '._getDefaultLoader', ->
    context 'file is js', ->
      Given -> @file =
        ext: sinon.stub().returns '.js'
      When -> @loader = @subject._getDefaultLoader @file
      Then -> @loader.should.equal 'require'
      
    context 'file is json', ->
      Given -> @file =
        ext: sinon.stub().returns '.json'
      When -> @loader = @subject._getDefaultLoader @file
      Then -> @loader.should.equal 'require'

    context 'file is neither js nor json', ->
      Given -> @file =
        ext: sinon.stub().returns '.txt'

      context 'and there is a callback', ->
        When -> @loader = @subject._getDefaultLoader @file, 'cb'
        Then -> @loader.should.equal 'readFile'

      context 'and there is no callback', ->
        When -> @loader = @subject._getDefaultLoader @file
        Then -> @loader.should.equal 'readFileSync'
