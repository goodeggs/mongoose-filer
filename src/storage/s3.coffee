async = require 'async'
knox = require 'knox'

module.exports = storage = (config) ->
  client = knox.createClient
    key: config.access_key_id
    secret: config.secret_access_key
    bucket: config.bucket

  Store: class Store

    constructor: (@attachment) ->
      @pendingWrites = []

    dir: (style) ->
      "/#{@attachment.prefix}/#{@attachment.id}/#{style}"

    path: (style) ->
      "#{@dir(style)}/#{@attachment.name}#{@attachment.extension}"

    flushWrites: (cb) ->
      store = @
      writes = for { style, file } in store.pendingWrites
        do (style, file) =>
          (done) ->
            console.log "Putting file to #{store.path(style)}"
            client.putFile file, store.path(style), 'Content-Type': store.attachment.file.type, done

      async.parallel writes, (err) ->
        return cb(err) if err?
        store.pendingWrites = []
        cb()

    delete: (style) ->

    copyToLocalFile: (style, path) ->
