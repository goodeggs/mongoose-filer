async = require 'async'
assert = require 'assert'
path = require 'path'

exports = module.exports = class Storage

  constructor: (@attachedFile) ->
    @pendingWrites = []
    @pendingDeletes = []

  path: (style) ->
    att = @attachedFile
    path.join '/', att.modelName, att.modelId, att.attributeName, "#{att.id}_#{style}#{att.extension}"

  url: (style) ->
    "#{Storage.baseUrl}#{@path(style)}"

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
    store = @
    deletes = for { style } in store.pendingDeletes
      do (style) =>
        (done) -> store.delete style, done

    async.parallel deletes, (err) ->
      return cb(err) if err?
      store.pendingDeletes = []
      cb()

  write: (style, file, cb) ->
    throw "Storage adapter not loaded"

  delete: (style, cb) ->
    throw "Storage adapter not loaded"

  copyToLocalFile: (style, file, cb) ->
    throw "Storage adapter not loaded"


exports.baseUrl = "http://localhost:3000/images"

exports.configure = (config) ->
  Storage.baseUrl = config.baseUrl if config.baseUrl?

  adapter = Object.keys(config.storage)[0]
  assert.ok(adapter, "Storage details are not in config")

  # Mix in adapter
  require("./#{adapter}")(Storage, config.storage[adapter])
