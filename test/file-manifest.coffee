describe 'manifesto', ->
  Given -> @pedestrian =
    walk: sinon.stub()
  Given -> @subject = sandbox 'lib/manifesto',
    underscore: _
    './pedestrian': @pedestrian
    'dir/foo/bar.js': 'foo/bar'
    'dir/baz-quux.js': 'baz-quux'
    'dir/some-long/nested/path.js': 'some-long/nested/path'

  context 'default reducer', ->
    Given -> @pedestrian.walk.withArgs('dir', []).returns [
      'foo/bar.js', 'baz-quux.js', 'some-long/nested/path.js'
    ]
    When -> @result = @subject.generate('dir')
    Then -> _.fix(@result).should.eql
      fooBar: 'foo/bar'
      bazQuux: 'baz-quux'
      someLongNestedPath: 'some-long/nested/path'
    
  context 'custom reducer', ->
    Given -> @pedestrian.walk.withArgs('dir', []).returns(['foo', 'bar', 'baz'])
    Given -> @reducer = (memo, item) ->
      memo[item] = item.split('').reverse().join('')
      return memo
    When -> @result = @subject.generate('dir', @reducer)
    Then -> _.fix(@result).should.eql
      foo: 'oof'
      bar: 'rab'
      baz: 'zab'

  context 'with patterns', ->
    When -> @subject.generate('dir', ['pattern1', 'pattern2'])
    Then -> @pedestrian.walk.calledWith('dir', ['pattern1', 'pattern2'])
