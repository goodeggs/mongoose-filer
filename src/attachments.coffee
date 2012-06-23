imagemagick = require 'imagemagick'
mkdirp = require 'mkdirp'
async = require 'async'

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

module.exports = attachments = (config) ->

  Processor: class Processor

    constructor: (@file, @options={}) ->
      @styles = @options.styles or {}
      @id = @options.id or new Date().getTime()
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
          {
            style: style
            path: destFile
            args: args
            convert: (cb) ->
              mkdirp dir, (err) ->
                return cb(err) if err?
                imagemagick.convert args, cb
          }

    convert: (cb) ->
      conversions = @conversions()
      async.parallel (c.convert for c in conversions), cb

    dir: (style) ->
      "#{config.storage.dir.path}/#{config.prefix}/#{@id}/#{style}"

    path: (style) ->
      "#{@dir(style)}/#{@name}#{@extension}"

