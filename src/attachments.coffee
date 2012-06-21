imagemagick = require 'imagemagick'
mkdirp = require 'mkdirp'
async = require 'async'

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

module.exports = attachments = (config) ->

  Attachment: class Attachments

    constructor: (@file, @options={}) ->
      @id = @options.id or new Date().getTime()
      @name = @options.name or @file.name.replace /(\..*?)$/, ''
      @extension = extensions[@file.type]

    conversions: () ->
      conversions = for style, conversion of config.styles
        do (style, conversion) =>
          dir = @dir style
          destFile = @path style
          args = [@file.path, '-resize', conversion]
          # See http://www.imagemagick.org/Usage/resize/#fill
          if groups = conversion.match /^(.*)\^$/
            args = args.concat ['-gravity', 'center', '-extent', groups[1]]
          args.push destFile
          {
            args: args
            convert: (cb) ->
              mkdirp dir, (err) ->
                return cb(err) if err?
                imagemagick.convert args, cb
          }

    convert: (cb) ->
      conversions = @conversions()
      console.log "Converting:", (c.args for c in conversions)
      async.series (c.convert for c in conversions), cb

    dir: (style) ->
      "#{config.storage.dir.path}/#{config.prefix}/#{@id}/#{style}"

    path: (style) ->
      "#{@dir(style)}/#{@name}#{@extension}"
