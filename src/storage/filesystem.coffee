fs = require 'fs-extra'
async = require 'async'

module.exports = storage = (config) ->

  Store: class Store
    
    constructor: (@attachment) ->
      @pendingWrites = []

    dir: (style) ->
      "#{config.path}/#{@attachment.prefix}/#{@attachment.id}/#{style}"

    path: (style) ->
      "#{@dir(style)}/#{@attachment.name}#{@attachment.extension}"

    flushWrites: (cb) ->
      store = @
      writes = for { style, file } in store.pendingWrites
        do (style, file) =>
          (done) ->
            fs.mkdir store.dir(style), (err) ->
              return done(err) if err?
              fs.copy file, store.path(style), done

      async.parallel writes, (err) ->
        return cb(err) if err?
        store.pendingWrites = []
        cb()

    delete: (style) ->

    copyToLocalFile: (style, path) ->
