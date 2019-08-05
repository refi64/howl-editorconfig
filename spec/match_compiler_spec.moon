match_compiler = require '../match_compiler'

say = require 'say'

say\set 'assertion.is_match.postitive', 'Expected %s to match %s'
say\set 'assertion.is_match.negative', 'Expected %s to not match %s'

is_match = (state, arguments) ->
  pattern = match_compiler arguments[1]
  return pattern\match arguments[2]

assert\register 'assertion', 'match', is_match, 'assertion.is_match.postitive',
                'assertion.is_match.negative'

describe 'match compiler', ->
  it 'compiles basic patterns', ->
    assert.is_match 'abc', 'abc'
    assert.is_not_match 'abc', 'ab'
    assert.is_not_match 'abc', 'bc'
    assert.is_not_match 'abc', 'a'

  it 'compiles escaped characters', ->
    assert.is_match '\\?\\a', '?a'
    assert.is_not_match '\\?\\a', 'aa'
    assert.is_not_match '\\?', 'ab'

  it 'compiles sets', ->
    assert.is_match '[abc]', 'a'
    assert.is_match '[!abc]', 'z'
    assert.is_not_match '[abc]', 'z'
    assert.is_not_match '[!abc]', 'a'

  it 'compiles braced sets', ->
    assert.is_match '{abc,def}', 'abc'
    assert.is_match '{abc,def}', 'def'
    assert.is_match '{abc,}', ''
    assert.is_not_match '{abc,def}', 'xyz'
    assert.is_not_match '{abc,def}', 'ab'
    assert.is_not_match '{abc,}', 'ab'

  it 'compiles basic globs', ->
    assert.is_match 'a*', 'a'
    assert.is_match 'a*', 'abc'
    assert.is_match 'a**', 'a'
    assert.is_match 'a**', 'abc'
    assert.is_not_match '*', 'ab/c'
    assert.is_match '**', 'ab/c'

  it 'compiles complex globs', ->
    assert.is_match '*.py', '.py'
    assert.is_match '*.py', 'xyz.py'
    assert.is_match '*.py', 'xyz.py.py.py'
    assert.is_not_match '*.py', 'xyz/abc.py.py'
    assert.is_match '**.py', 'xyz/abc.py.py'

    it 'compiles globs with right hand sides', ->
      assert.is_match '*.py{,x}', '.py'
      assert.is_match '*.py{,x}', '.pyx'
