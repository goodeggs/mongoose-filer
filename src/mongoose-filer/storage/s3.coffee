knox = require 'knox'
_ = require 'underscore'

module.exports = s3 = (Store, config) ->

  client = knox.createClient
    key: config.access_key_id
    secret: config.secret_access_key
    bucket: config.bucket

  defaultHeaders = config.s3Headers or {}

  Store.prototype.write = (style, file, cb) ->
    path = @path(style)
    console.log "S3: writing #{path}"
    client.putFile file, @path(style), _(defaultHeaders).extend(@attachedFile.s3Headers, 'Content-Type': @attachedFile.file.type), (err, res) ->
      if res.statusCode isnt 200
        err ?= new Error "#{res.statusCode} Error from S3 put"
      return cb(err, res)


  Store.prototype.delete = (style, cb) ->
    path = @path(style)
    console.log "S3: deleting #{path}"
    client.deleteFile @path(style), (err, res) ->
      if res.statusCode isnt 204
        err ?= new Error "#{res.statusCode} Error from S3 delete"
      return cb(err, res)


