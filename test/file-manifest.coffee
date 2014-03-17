describe 'file-manifest', ->
  Given -> @pedestrian =
    walk: sinon.stub()
  Given -> @subject = sandbox 'lib/file-manifest',
    underscore: _
    './pedestrian': @pedestrian
    'dir/foo/bar.js': 'foo/bar'
    'dir/baz-quux.js': 'baz-quux'
    'dir/some-long/nested/path.js': 'some-long/nested/path'

  context 'sync', ->
    context 'default reducer', ->
      Given -> @pedestrian.walk.withArgs('dir').returns [
        'foo/bar.js', 'baz-quux.js', 'some-long/nested/path.js'
      ]
      When -> @result = @subject.generate('dir')
      Then -> expect(_.fix(@result)).to.deep.equal
        fooBar: 'foo/bar'
        bazQuux: 'baz-quux'
        someLongNestedPath: 'some-long/nested/path'
      
    context 'custom reducer', ->
      Given -> @pedestrian.walk.withArgs('dir').returns ['foo', 'bar', 'baz']
      Given -> @reducer = (memo, item) ->
        memo[item] = item.split('').reverse().join ''
        return memo
      When -> @result = @subject.generate 'dir', @reducer
      Then -> expect(_.fix(@result)).to.deep.equal
        foo: 'oof'
        bar: 'rab'
        baz: 'zab'

    context 'with patterns', ->
      When -> @subject.generate 'dir', ['pattern1', 'pattern2']
      Then -> @pedestrian.walk.calledWith 'dir', ['pattern1', 'pattern2']

  context 'async', ->
    Given -> @cb = sinon.stub()
    Given -> @fn = (err, manifest) =>
      @cb(err, manifest)
    context 'default reducer', ->
      Given -> @pedestrian.walk.withArgs('dir', []).callsArgWith 2, null, [
        'foo/bar.js', 'baz-quux.js', 'some-long/nested/path.js'
      ]
      When -> @subject.generate 'dir', @fn
      Then -> expect(@cb).to.have.been.calledWith null,
        fooBar: 'foo/bar'
        bazQuux: 'baz-quux'
        someLongNestedPath: 'some-long/nested/path'

    context 'custom reducer', ->
      Given -> @pedestrian.walk.withArgs('dir').callsArgWith 2, null, ['foo', 'bar', 'baz']
      Given -> @reducer = (memo, item, cb) ->
        memo[item] = item.split('').reverse().join ''
        cb null, memo
      When -> @subject.generate 'dir', @reducer, @fn
      Then -> expect(@cb).to.have.been.calledWith null,
        foo: 'oof'
        bar: 'rab'
        baz: 'zab'

    context 'with patterns', ->
      Given -> @reducer = sinon.spy()
      When -> @subject.generate 'dir', ['pattern1', 'pattern2'], @reducer, @fn
      Then -> @pedestrian.walk.calledWith 'dir', ['pattern1', 'pattern2'], sinon.match.func
