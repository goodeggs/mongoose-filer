async = require 'async'
assert = require 'assert'

exports = module.exports = (config) ->

  adapter = Object.keys(config)[0]
  assert.ok(adapter, "Storage is not configured")

  # Mix in adapter
  require("./#{adapter}")(exports.Store, config[adapter])

  Store: exports.Store

exports.Store = class Store

  constructor: (@attachment) ->
    @pendingWrites = []

  path: (style) ->
    "/#{@attachment.prefix}/#{@attachment.id}/#{style}/#{@attachment.name}#{@attachment.extension}"

  flushWrites: (cb) ->
    store = @
    writes = for { style, file } in store.pendingWrites
      do (style, file) =>
        (done) -> store.write style, file, done

    async.parallel writes, (err) ->
      return cb(err) if err?
      store.pendingWrites = []
      cb()

  flushDeletes: (cb) ->
    cb()

  write: (style, file, cb) ->
    throw "Storage adapter not loaded"

  delete: (style, cb) ->
    throw "Storage adapter not loaded"

  copyToLocalFile: (style, file, cb) ->
    throw "Storage adapter not loaded"
