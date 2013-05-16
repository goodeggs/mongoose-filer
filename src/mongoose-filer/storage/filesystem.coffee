fs = require 'fs-extra'
path = require 'path'

module.exports = filesystem = (Store, config) ->

  copyFile = (srcFile, destFile, cb) ->
    nodeFs = require("fs")
    fdr = nodeFs.createReadStream(srcFile)
    fdw = nodeFs.createWriteStream(destFile)
    fdr.on "end", -> cb null
    fdr.pipe fdw

  Store.prototype.write = (style, file, cb) ->
    destFile = @filePath style
    fs.mkdirs path.dirname(destFile), (err) ->
      return cb(err) if err?
      copyFile file, destFile, cb

  Store.prototype.delete = (style, cb) ->
      fs.unlink @filePath(style), (err) ->
        if err?.code == 'ENOENT' # Does not exist
          console.error "Filesystem: file not found for delete. Ignoring", err.path
          return cb()
        cb(err)

  Store.prototype.filePath = (style) ->
    path.join config.dir, @path(style)
