imagemagick = require 'imagemagick'
mkdirp = require 'mkdirp'
async = require 'async'

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

module.exports = attachments = (config) ->
  console.log "Attachments initialized with config:", config

  Attachment: class Attachments

    constructor: (@file) ->

    conversions: () ->
      name = @file.name.replace /(\..*?)$/, ''
      id = new Date().getTime()
      conversions = for style, conversion of config.styles
        do (style, conversion) =>
          path = "#{config.storage.dir.path}/#{config.prefix}/#{id}/#{style}"
          destFile = "#{path}/#{name}#{extensions[@file.type]}"
          args = [@file.path, '-resize', conversion]
          # See http://www.imagemagick.org/Usage/resize/#fill
          if groups = conversion.match /^(.*)\^$/
            args = args.concat ['-gravity', 'center', '-extent', groups[1]]
          args.push destFile
          {
            args: args
            convert: (cb) ->
              mkdirp path, (err) ->
                return cb(err) if err?
                imagemagick.convert args, cb
          }

    convert: (cb) ->
      conversions = @conversions()
      console.log "Converting:", (c.args for c in conversions)
      async.series (c.convert for c in conversions), cb
