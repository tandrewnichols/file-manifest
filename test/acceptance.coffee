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

  describe 'with custom reducer', ->
    When -> @manifest = @fm.generate "#{__dirname}/fixtures", (memo, file) ->
      memo[require('path').basename(file, '.js')] = require(file).split('').reverse().join('')
      return memo
    Then -> expect(@manifest).to.deep.equal
      foo: 'oof'
      bar: 'rab'
      quux: 'xuuq'
