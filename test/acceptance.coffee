_ = require 'lodash'

normalize = (manifest) ->
  return _(manifest).keys().reduce( (memo, key) ->
    memo[key.split('file-manifest/test/fixtures')[1]] = manfiest[key]
    memo
  , {})

describe 'acceptance', ->
  Given -> @fm = require '../lib/file-manifest'

  describe 'sync', ->
    When -> @manifest = @fm.generate "#{__dirname}/fixtures"
    Then -> expect(@manifest).to.deep.equal
      foo: 'foo'
      bar: 'bar'
      bazQuux: 'quux'

  describe 'async', ->
    When (done) -> @fm.generate "#{__dirname}/fixtures", (err, @manifest) => done()
    Then -> expect(@manifest).to.deep.equal
      foo: 'foo'
      bar: 'bar'
      bazQuux: 'quux'

  describe 'with patterns', ->
    When -> @manifest = @fm.generate "#{__dirname}/fixtures", ['*.js']
    Then -> expect(@manifest).to.deep.equal
      foo: 'foo'
      bar: 'bar'
