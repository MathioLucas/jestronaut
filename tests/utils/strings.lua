local stringsLib = require "jestronaut.utils.strings"

describe('strings utils', function()
  it('split', function()
    expect(stringsLib.split('a b c', ' ')):toEqual({'a', 'b', 'c'})
    expect(stringsLib.split('a b c', 'b')):toEqual({'a ', ' c'})
    expect(stringsLib.split('a b c', 'd')):toEqual({'a b c'})
    expect(stringsLib.split('a b c', '')):toEqual({'a', ' ', 'b', ' ', 'c'})
    expect(stringsLib.split('a b c', nil)):toEqual({'a', 'b', 'c'})
  end)

  it('implodePath', function()
    expect(stringsLib.implodePath({})):toEqual('')
    expect(stringsLib.implodePath({'a'})):toEqual('a')
    expect(stringsLib.implodePath({'a', 'b'})):toEqual('a.b')
    expect(stringsLib.implodePath({'a', 'b', 1, 2, 'c'})):toEqual('a.b[1][2].c')
    expect(stringsLib.implodePath({'a', 'b', 1, 2, 'c', 3})):toEqual('a.b[1][2].c[3]')
    expect(stringsLib.implodePath({true, false, 1, 2, 3, 'a', 'b', 'c'})):toEqual('[true][false][1][2][3].a.b.c')
  end)

  it('normalizePath', function()
    expect(stringsLib.normalizePath('a/b/c')):toEqual('./a/b/c')
    expect(stringsLib.normalizePath('a\\b\\c')):toEqual('./a/b/c')
    expect(stringsLib.normalizePath('a/b/c/')):toEqual('./a/b/c')
    expect(stringsLib.normalizePath('a/b/c//')):toEqual('./a/b/c')
    expect(stringsLib.normalizePath('a/b/c///')):toEqual('./a/b/c')
    expect(stringsLib.normalizePath('a/b/c////')):toEqual('./a/b/c')
    expect(stringsLib.normalizePath('a/b/c//////')):toEqual('./a/b/c')
  end)

  it('prefixLines', function()
    expect(stringsLib.prefixLines('a\nb\nc', 'x')):toEqual('xa\nxb\nxc')
    expect(stringsLib.prefixLines('a\nb\nc', 'x\ny')):toEqual('x\nya\nx\nyb\nx\nyc')
    expect(stringsLib.prefixLines('a\nb\nc', '\t')):toEqual('\ta\n\tb\n\tc')
    expect(stringsLib.prefixLines('a\nb\nc', '\t\t')):toEqual('\t\ta\n\t\tb\n\t\tc')
  end)
end)
    