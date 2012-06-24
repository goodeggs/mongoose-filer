Processor = require("./processor").Processor
Store = require("./storage").Store

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

exports = module.exports = class Attachment

    constructor: (@id, @options={}) ->
      @id ?= new Date().getTime()
      @prefix = @options.prefix or "default"
      @store = new Store(@)
      @file(@options.file) if @options.file?

    file: (file) ->
      @file = file
      @extension = extensions[@file.type]
      @name = @options.name or @file.name.replace /(\..*?)$/, ''

    save: (cb) ->
      processor = new Processor(@file, styles: @options.styles)
      processor.on 'convert', (result) => @store.pendingWrites.push result
      processor.on 'done', => @store.flushWrites cb
      processor.on 'error', cb
      processor.convert()

    path: (style) ->
      @store.path(style)
