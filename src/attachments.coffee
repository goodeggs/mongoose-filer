imagemagick = require 'imagemagick'
async = require 'async'
EventEmitter = require('events').EventEmitter
assert = require 'assert'
path = require 'path'

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

tmpFile = (tmpDir) ->
  name = ""
  name += Math.floor(Math.random() * 16).toString(16) for i in [0...32]
  path.join tmpDir, name

module.exports = attachments = (config) ->
  tmpDir = config.tmpDir or process.env.TMPDIR
  assert.ok(path.existsSync(tmpDir), "#{tmpDir} does not exist")

  Attachment: class Attachment

    constructor: (@id, @options={}) ->
      @id = @options.id or new Date().getTime()
      @prefix = @options.prefix or "default"
      @name = @options.name or @file.name.replace /(\..*?)$/, ''
      @extension = extensions[@file.type]


  Processor: class Processor extends EventEmitter

    constructor: (@file, @options={}) ->

    conversions: () ->
      destFileBase = tmpFile(tmpDir)
      conversions = for style, conversion of @options.styles
        do (style, conversion) =>
          destFile = "#{destFileBase}-#{style}"
          args = [@file.path, '-resize', conversion]
          # See http://www.imagemagick.org/Usage/resize/#fill
          if groups = conversion.match /^(.*)\^$/
            args = args.concat ['-gravity', 'center', '-extent', groups[1]]
          args.push destFile
          processor = @
          {
            style: style
            path: destFile
            args: args
            convert: (cb) ->
              imagemagick.convert args, (err) ->
                return cb("Imagemagick #{err}") if err?
                processor.emit('convert', style: style, file: destFile)
                cb(null)
          }

    convert: (cb) ->
      conversions = @conversions()
      async.parallel (c.convert for c in conversions), (err) =>
        @emit('error', err) if err?
        @emit('done')
        cb(err) if cb?

