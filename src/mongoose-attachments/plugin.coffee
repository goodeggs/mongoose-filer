async = require 'async'
mongoose = require 'mongoose'
_ = require 'underscore'
Attachment = require './attachment'

Attachments = new mongoose.Schema
  name: type: String, required: true
  fileName: String
  contentType: String
  createdAt: type: Date, default: Date.now
, strict: true

Attachments.virtual('file')
  .get ->
    @_file
  .set (value) ->
    @_file = value

Attachments.path('contentType').validate (v) ->
  contentTypes = @parent?.schema.attachments[@name].contentType
  return !contentTypes? or (v in contentTypes)
, "acceptable content type"


exports = module.exports = (schema, options) ->

  if !schema.path 'attachments'
    schema.attachments = {} # Store options per attachment name
    schema.add 'attachments': [ Attachments ]
    schema.pre 'save', (next) ->
      options.prefix ?= @modelName
      saves = for attachment in @attachments when attachment.file?
        ( (cb) -> new Attachment(attachment.id, options).save cb)
      async.parallel saves, next

  name = options.name
  schema.attachments[name] = options

  schema.virtual(name).get ->
    _(@attachments).find (a) -> a.name == name

  schema.virtual(name).set (value) ->
    (existing = @get(name)) and existing.remove()
    if value.path # it's a file
      @attachments.push
        name: name
        fileName: value.name
        contentType: value.type
        file: value.path

exports.MongooseAttachment = mongoose.model 'Attachment', Attachments


