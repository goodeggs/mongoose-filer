inflect = require "inflect"
path = require "path"
Processor = require "./processor"
Storage = require "./storage"

extensions =
  "image/jpeg": ".jpg"
  "image/png": ".png"
  "image/gif": ".gif"

exports = module.exports = class AttachedFile

    constructor: (@id, options={}) ->
      @modelName = inflect.underscore options.modelName
      @modelId = options.modelId
      @attributeName = inflect.underscore options.attributeName
      @styles = options.styles or []
      @store = new Storage(@)
      @s3Headers = options.s3Headers or {}
      @file = options.file
      if @file
        @fileName = @file.name
        @extension = extensions[@file.type] or path.extname(@fileName)

    save: (cb) ->
      @store.pendingWrites.push style: 'original', file: @file.path
      processor = new Processor(@file, styles: @styles)
      processor.on 'convert', (result) => @store.pendingWrites.push result
      processor.on 'done', => @store.flushWrites cb
      processor.on 'error', cb
      processor.convert()


    remove: (cb) ->
      @store.pendingDeletes.push style: 'original'
      @store.pendingDeletes.push style: name for name of @styles
      @store.flushDeletes(cb)

    path: (style) ->
      @store.path(style)

    url: (style) ->
      @store.url(style)
