imagemagick = require 'imagemagick'
mkdirp = require 'mkdirp'
async = require 'async'
EventEmitter = require('events').EventEmitter

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

module.exports = attachments = (config) ->

  Processor: class Processor extends EventEmitter

    constructor: (@file, @options={}) ->
      @styles = @options.styles or {}
      @id = @options.id or new Date().getTime()
      @prefix = @options.prefix or "default"
      @name = @options.name or @file.name.replace /(\..*?)$/, ''
      @extension = extensions[@file.type]

    conversions: () ->
      conversions = for style, conversion of @styles
        do (style, conversion) =>
          dir = @dir style
          destFile = @path style
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
              mkdirp dir, (err) ->
                return cb(err) if err?
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

    dir: (style) ->
      "#{config.storage.dir.path}/#{@prefix}/#{@id}/#{style}"

    path: (style) ->
      "#{@dir(style)}/#{@name}#{@extension}"

