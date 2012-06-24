Processor = require "./processor"
Storage = require "./storage"

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

exports = module.exports = class Attachment

    constructor: (@id, @options={}) ->
      @id ?= new Date().getTime()
      @prefix = @options.prefix or "default"
      @styles = @options.styles or []
      @store = new Storage(@)
      @file = @options.file
      if @options.name
        @fileName = @options.name
      else if @file
        @fileName = @file.name
        @fileName?.replace(/(\..*?)$/,  extensions[@file.type]) if extensions[@file.type]

    save: (cb) ->
      @store.pendingWrites.push style: 'original', file: @file.path
      processor = new Processor(@file, styles: @styles)
      processor.on 'convert', (result) => @store.pendingWrites.push result
      processor.on 'done', => @store.flushWrites cb
      processor.on 'error', cb
      processor.convert()

    path: (style) ->
      @store.path(style)

    url: (style) ->
      @store.url(style)
