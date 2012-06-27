fs = require 'fs-extra'
path = require 'path'

module.exports = filesystem = (Store, config) ->

  Store.prototype.write = (style, file, cb) ->
    destFile = @filePath style
    fs.mkdir path.dirname(destFile), (err) ->
      return cb(err) if err?
      fs.copy file, destFile, cb

  Store.prototype.delete = (style, cb) ->
      fs.unlink @filePath(style), (err) ->
        return cb() if err?.code == 'ENOENT' # Does not exist
        cb(err)

  Store.prototype.filePath = (style) ->
    path.join config.dir, @path(style, @attachedFile.pathAttributes)
