knox = require 'knox'

module.exports = s3 = (Store, config) ->

  client = knox.createClient
    key: config.access_key_id
    secret: config.secret_access_key
    bucket: config.bucket

  Store.prototype.write = (style, file, cb) ->
    path = @path(style)
    console.log "S3: writing #{path}"
    client.putFile file, @path(style), 'Content-Type': @attachedFile.file.type, cb

