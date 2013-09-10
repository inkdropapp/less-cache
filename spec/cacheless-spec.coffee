fs = require 'fs'
{join} = require 'path'

tmp = require 'tmp'
fstream = require 'fstream'

LessCache = require '../src/cacheless'

describe "LessCache", ->
  [cache, fixturesDir] = []

  beforeEach ->
    fixturesDir = null
    tmp.dir (error, tempDir) ->
      reader = fstream.Reader(join(__dirname, 'fixtures'))
      reader.on 'end', ->
        fixturesDir = tempDir
        cache = new LessCache(importPaths: [join(fixturesDir, 'imports-1'), join(fixturesDir, 'imports-2')])
      reader.pipe(fstream.Writer(tempDir))

    waitsFor -> fixturesDir?

  describe "::readFileSync(filePath)", ->
    [css] = []

    beforeEach ->
      css = cache.readFileSync(join(fixturesDir, 'imports.less'))

    it "returns the compiled CSS for a given LESS file path", ->
      expect(css).toBe """
        body {
          a: 1;
          b: 2;
          c: 3;
          d: 4;
        }

      """

    it "reflects changes to the file being read", ->
      fs.writeFileSync(join(fixturesDir, 'imports.less'), 'body { display: block; }')
      css = cache.readFileSync(join(fixturesDir, 'imports.less'))
      expect(css).toBe """
        body {
          display: block;
        }

      """

    it "reflects changes to files imported by the file being read", ->
      fs.writeFileSync(join(fixturesDir, 'b.less'), '@b: 20;')
      css = cache.readFileSync(join(fixturesDir, 'imports.less'))
      expect(css).toBe """
        body {
          a: 1;
          b: 20;
          c: 3;
          d: 4;
        }

      """

    it "reflects changes to files on the import path", ->
      fs.writeFileSync(join(fixturesDir, 'imports-1', 'd.less'), '@d: 40;')
      css = cache.readFileSync(join(fixturesDir, 'imports.less'))
      expect(css).toBe """
        body {
          a: 1;
          b: 2;
          c: 3;
          d: 40;
        }

      """

      fs.unlinkSync(join(fixturesDir, 'imports-1', 'c.less'))
      css = cache.readFileSync(join(fixturesDir, 'imports.less'))
      expect(css).toBe """
        body {
          a: 1;
          b: 2;
          c: 30;
          d: 40;
        }

      """

      fs.writeFileSync(join(fixturesDir, 'imports-1', 'd.less'), '@d: 400;')
      css = cache.readFileSync(join(fixturesDir, 'imports.less'))
      expect(css).toBe """
        body {
          a: 1;
          b: 2;
          c: 30;
          d: 400;
        }

      """
