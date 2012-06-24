knox = require 'knox'

module.exports = s3 = (Store, config) ->

  client = knox.createClient
    key: config.access_key_id
    secret: config.secret_access_key
    bucket: config.bucket

  Store.prototype.write = (style, file, cb) ->
    client.putFile file, @path(style), 'Content-Type': @attachment.file.type, cb

