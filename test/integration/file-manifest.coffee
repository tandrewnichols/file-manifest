sinon = require('sinon')
path = require('path')

describe 'integration', ->
  Given -> @fm = require '../../lib/file-manifest'

  describe 'sync', ->
    describe 'with relative dir', ->
      When -> @manifest = @fm.generate "./fixtures"
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        bazQuux: 'quux'
        blah: 'json'

    describe 'with dir', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures"
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        bazQuux: 'quux'
        blah: 'json'

    describe 'with dir and patterns as array', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", match: ['*.js']
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with multiple patterns', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", match: ['**/*.js', '*.json', '!foo*']
      Then -> @manifest.should.eql
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir and patterns as string', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", match: '*.js'
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and reducer', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", reduce: (manifest, file) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        return manifest
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'
        quux: 'xuuq'
        blah: 'nosj'

    describe 'with dir, patterns, and reducer', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", { match: ['*.js'], reduce: (manifest, file) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        return manifest
      }
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'

    describe 'with dir and options.memo', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", { memo: { hello: 'world' } }
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        bazQuux: 'quux'
        blah: 'json'
        hello: 'world'

    describe 'with dir and options.name as function', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: (file) -> file.name().split('').reverse().join('') }
      Then -> @manifest.should.eql
        oof: 'foo'
        rab: 'bar'
        xuuq: 'quux'
        halb: 'json'

    describe 'with dir and options.name as string', ->
      context 'camelCase', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'camelCase' }
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'dash', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'dash' }
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz-quux': 'quux'

      context 'pipe', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'pipe' }
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz|quux': 'quux'

      context 'class', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'class' }
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          BazQuux: 'quux'

      context 'lower', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'lower' }
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazquux: 'quux'

      context 'upper', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'upper' }
        Then -> @manifest.should.eql
          FOO: 'foo'
          BAR: 'bar'
          BLAH: 'json'
          BAZQUUX: 'quux'

      context 'underscore', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'underscore' }
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          baz_quux: 'quux'

      context 'human', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { name: 'human' }
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          'Baz quux': 'quux'

    describe 'with dir and options.load as function', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures", load: (file) -> file.ext()
      Then -> @manifest.should.eql
        foo: '.js'
        bar: '.js'
        blah: '.json'
        bazQuux: '.js'

    describe 'with dir and options.load as string', ->
      context 'require', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { load: 'require' }
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'readfile', ->
        When -> @manifest = @fm.generate "#{__dirname}/fixtures", { load: 'readFile' }
        Then -> @manifest.should.eql
          foo: 'module.exports = \'foo\';\n'
          bar: 'module.exports = \'bar\';\n'
          blah: '"json"\n'
          bazQuux: 'module.exports = \'quux\';\n'

    describe 'with dir, options.memo, and reducer', ->
      When -> @manifest = @fm.generate "#{__dirname}/fixtures",
        memo:
          a: []
          b: []
        reduce: (manifest, file) -> manifest.b.push(file.name()); return manifest
      And -> @manifest.b.sort()
      Then -> @manifest.should.eql
        a: []
        b: ['bar', 'blah', 'foo', 'quux']

    describe 'with options.reduce as a string', ->
      context 'nested', ->
        When -> @manifest = @fm.generate "./fixtures", reduce: 'nested'
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          baz:
            quux: 'quux'
          blah: 'json'

      context 'list without memo', ->
        When -> @manifest = @fm.generate './fixtures', reduce: 'list'
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'no list but with array memo', ->
        When -> @manifest = @fm.generate './fixtures', memo: []
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'objectList', ->
        When -> @manifest = @fm.generate './fixtures', reduce: 'objectList'
        Then -> @manifest.should.eql [
          name: 'bar',
          contents: 'bar'
        ,
          name: 'blah'
          contents: 'json'
        ,
          name: 'foo'
          contents: 'foo'
        ,
          name: 'baz/quux'
          contents: 'quux'
        ]

  describe 'async', ->
    describe 'with a relative dir', ->
      When (done) -> @fm.generate "./fixtures", (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures", (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir and options.match', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures", match: ['*.js'], (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and options.reduce', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures", reduce: (manifest, file, cb) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        cb(null, manifest)
      , (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'
        quux: 'xuuq'
        blah: 'nosj'

    describe 'with dir, options.match, and options.reduce', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures", { match: ['*.js'], reduce: (manifest, file, cb) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        cb(null, manifest)
      }, (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'

    describe 'with dir and options.match as string', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures", { match: '*.js' }, (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and options.memo', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures", { memo: { hello: 'world' } }, (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'
        hello: 'world'

    describe 'with dir and options.name as function', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures",
        name: (file) -> file.name().split('').reverse().join('')
      , (err, @manifest) => done()
      Then -> @manifest.should.eql
        oof: 'foo'
        rab: 'bar'
        halb: 'json'
        xuuq: 'quux'

    describe 'with dir and options.name as string', ->
      context 'camelCase', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'camelCase' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'dash', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'dash' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz-quux': 'quux'

      context 'pipe', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'pipe' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz|quux': 'quux'

      context 'class', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'class' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          BazQuux: 'quux'

      context 'lower', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'lower' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazquux: 'quux'

      context 'upper', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'upper' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          FOO: 'foo'
          BAR: 'bar'
          BLAH: 'json'
          BAZQUUX: 'quux'

      context 'underscore', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'underscore' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          baz_quux: 'quux'

      context 'human', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { name: 'human' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          'Baz quux': 'quux'

    describe 'with dir and options.load as function', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures",
        load: (file, cb) -> cb(null, file.ext())
      , (err, @manifest) => done()
      Then -> @manifest.should.eql
        foo: '.js'
        bar: '.js'
        blah: '.json'
        bazQuux: '.js'

    describe 'with dir and options.load as string', ->
      context 'require', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { load: 'require' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'readfile', ->
        When (done) -> @fm.generate "#{__dirname}/fixtures", { load: 'readFile' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'module.exports = \'foo\';\n'
          bar: 'module.exports = \'bar\';\n'
          blah: '"json"\n'
          bazQuux: 'module.exports = \'quux\';\n'

    describe 'with dir, options.memo, and options.reduce', ->
      When (done) -> @fm.generate "#{__dirname}/fixtures",
        memo:
          a: []
          b: []
        reduce: (manifest, file, cb) ->
          manifest.b.push(file.name())
          cb(null, manifest)
      , (err, @manifest) => done()
      And -> @manifest.b.sort()
      Then -> @manifest.should.eql
        a: []
        b: ['bar', 'blah', 'foo', 'quux']

    describe 'with options.reduce as a string', ->
      context 'nested', ->
        When (done) -> @manifest = @fm.generate "./fixtures", { reduce: 'nested' }, (err, @manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          baz:
            quux: 'quux'
          blah: 'json'

      context 'list without memo', ->
        When (done) -> @manifest = @fm.generate './fixtures', { reduce: 'list' }, (err, @manifest) => done()
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'no list but with array memo', ->
        When (done) -> @manifest = @fm.generate './fixtures', { memo: [] }, (err, @manifest) => done()
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'objectList', ->
        When (done) -> @manifest = @fm.generate './fixtures', { reduce: 'objectList' }, (err, @manifest) => done()
        Then -> @manifest.should.eql [
          name: 'bar',
          contents: 'bar'
        ,
          name: 'blah'
          contents: 'json'
        ,
          name: 'foo'
          contents: 'foo'
        ,
          name: 'baz/quux'
          contents: 'quux'
        ]

  describe 'promise', ->
    describe 'with a relative dir', ->
      When (done) -> @fm.generatePromise("./fixtures").then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures").then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir and options.match', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures", match: ['*.js']).then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and options.reduce', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures", reduce: (manifest, file, cb) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        cb(null, manifest)
      ).then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'
        quux: 'xuuq'
        blah: 'nosj'

    describe 'with dir, options.match, and options.reduce', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { match: ['*.js'], reduce: (manifest, file, cb) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        cb(null, manifest)
      }).then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'

    describe 'with dir and options.match as string', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { match: '*.js' }).then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and options.memo', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { memo: { hello: 'world' } }).then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'
        hello: 'world'

    describe 'with dir and options.name as function', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures",
        name: (file) -> file.name().split('').reverse().join('')
      ).then (@manifest) => done()
      Then -> @manifest.should.eql
        oof: 'foo'
        rab: 'bar'
        halb: 'json'
        xuuq: 'quux'

    describe 'with dir and options.name as string', ->
      context 'camelCase', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'camelCase' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'dash', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'dash' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz-quux': 'quux'

      context 'pipe', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'pipe' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz|quux': 'quux'

      context 'class', ->
        When (done) -> @fm.generatePromise( "#{__dirname}/fixtures", { name: 'class' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          BazQuux: 'quux'

      context 'lower', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'lower' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazquux: 'quux'

      context 'upper', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'upper' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          FOO: 'foo'
          BAR: 'bar'
          BLAH: 'json'
          BAZQUUX: 'quux'

      context 'underscore', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'underscore' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          baz_quux: 'quux'

      context 'human', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { name: 'human' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          'Baz quux': 'quux'

    describe 'with dir and options.load as function', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures",
        load: (file, cb) -> cb(null, file.ext())
      ).then (@manifest) => done()
      Then -> @manifest.should.eql
        foo: '.js'
        bar: '.js'
        blah: '.json'
        bazQuux: '.js'

    describe 'with dir and options.load as string', ->
      context 'require', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { load: 'require' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'readfile', ->
        When (done) -> @fm.generatePromise("#{__dirname}/fixtures", { load: 'readFile' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'module.exports = \'foo\';\n'
          bar: 'module.exports = \'bar\';\n'
          blah: '"json"\n'
          bazQuux: 'module.exports = \'quux\';\n'

    describe 'with dir, options.memo, and options.reduce', ->
      When (done) -> @fm.generatePromise("#{__dirname}/fixtures",
        memo:
          a: []
          b: []
        reduce: (manifest, file, cb) ->
          manifest.b.push(file.name())
          cb(null, manifest)
      ).then (@manifest) => done()
      And -> @manifest.b.sort()
      Then -> @manifest.should.eql
        a: []
        b: ['bar', 'blah', 'foo', 'quux']

    describe 'with options.reduce as a string', ->
      context 'nested', ->
        When (done) -> @manifest = @fm.generatePromise("./fixtures", { reduce: 'nested' }).then (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          baz:
            quux: 'quux'
          blah: 'json'

      context 'list without memo', ->
        When (done) -> @manifest = @fm.generatePromise('./fixtures', { reduce: 'list' }).then (@manifest) => done()
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'no list but with array memo', ->
        When (done) -> @manifest = @fm.generatePromise('./fixtures', { memo: [] }).then (@manifest) => done()
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'objectList', ->
        When (done) -> @manifest = @fm.generatePromise('./fixtures', { reduce: 'objectList' }).then (@manifest) => done()
        Then -> @manifest.should.eql [
          name: 'bar',
          contents: 'bar'
        ,
          name: 'blah'
          contents: 'json'
        ,
          name: 'foo'
          contents: 'foo'
        ,
          name: 'baz/quux'
          contents: 'quux'
        ]

  describe 'event', ->
    describe 'with a relative dir', ->
      When (done) -> @fm.generateEvent("./fixtures").on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures").on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'

    describe 'with dir and options.match', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures", match: ['*.js']).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and options.reduce', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures", reduce: (manifest, file, cb) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        cb(null, manifest)
      ).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'
        quux: 'xuuq'
        blah: 'nosj'

    describe 'with dir, options.match, and options.reduce', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { match: ['*.js'], reduce: (manifest, file, cb) ->
        manifest[file.name()] = require(file.abs()).split('').reverse().join('')
        cb(null, manifest)
      }).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'oof'
        bar: 'rab'

    describe 'with dir and options.match as string', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { match: '*.js' }).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'

    describe 'with dir and options.memo', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { memo: { hello: 'world' } }).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: 'foo'
        bar: 'bar'
        blah: 'json'
        bazQuux: 'quux'
        hello: 'world'

    describe 'with dir and options.name as function', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures",
        name: (file) -> file.name().split('').reverse().join('')
      ).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        oof: 'foo'
        rab: 'bar'
        halb: 'json'
        xuuq: 'quux'

    describe 'with dir and options.name as string', ->
      context 'camelCase', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'camelCase' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'dash', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'dash' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz-quux': 'quux'

      context 'pipe', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'pipe' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          'baz|quux': 'quux'

      context 'class', ->
        When (done) -> @fm.generateEvent( "#{__dirname}/fixtures", { name: 'class' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          BazQuux: 'quux'

      context 'lower', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'lower' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazquux: 'quux'

      context 'upper', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'upper' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          FOO: 'foo'
          BAR: 'bar'
          BLAH: 'json'
          BAZQUUX: 'quux'

      context 'underscore', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'underscore' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          baz_quux: 'quux'

      context 'human', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { name: 'human' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          Foo: 'foo'
          Bar: 'bar'
          Blah: 'json'
          'Baz quux': 'quux'

    describe 'with dir and options.load as function', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures",
        load: (file, cb) -> cb(null, file.ext())
      ).on 'manifest', (@manifest) => done()
      Then -> @manifest.should.eql
        foo: '.js'
        bar: '.js'
        blah: '.json'
        bazQuux: '.js'

    describe 'with dir and options.load as string', ->
      context 'require', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { load: 'require' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          blah: 'json'
          bazQuux: 'quux'

      context 'readfile', ->
        When (done) -> @fm.generateEvent("#{__dirname}/fixtures", { load: 'readFile' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'module.exports = \'foo\';\n'
          bar: 'module.exports = \'bar\';\n'
          blah: '"json"\n'
          bazQuux: 'module.exports = \'quux\';\n'

    describe 'with dir, options.memo, and options.reduce', ->
      When (done) -> @fm.generateEvent("#{__dirname}/fixtures",
        memo:
          a: []
          b: []
        reduce: (manifest, file, cb) ->
          manifest.b.push(file.name())
          cb(null, manifest)
      ).on 'manifest', (@manifest) => done()
      And -> @manifest.b.sort()
      Then -> @manifest.should.eql
        a: []
        b: ['bar', 'blah', 'foo', 'quux']

    describe 'with options.reduce as a string', ->
      context 'nested', ->
        When (done) -> @manifest = @fm.generateEvent("./fixtures", { reduce: 'nested' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql
          foo: 'foo'
          bar: 'bar'
          baz:
            quux: 'quux'
          blah: 'json'

      context 'list without memo', ->
        When (done) -> @manifest = @fm.generateEvent('./fixtures', { reduce: 'list' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'no list but with array memo', ->
        When (done) -> @manifest = @fm.generateEvent('./fixtures', { memo: [] }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql ['bar', 'json', 'foo', 'quux']

      context 'objectList', ->
        When (done) -> @manifest = @fm.generateEvent('./fixtures', { reduce: 'objectList' }).on 'manifest', (@manifest) => done()
        Then -> @manifest.should.eql [
          name: 'bar',
          contents: 'bar'
        ,
          name: 'blah'
          contents: 'json'
        ,
          name: 'foo'
          contents: 'foo'
        ,
          name: 'baz/quux'
          contents: 'quux'
        ]
