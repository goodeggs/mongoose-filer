async = require 'async'
mongoose = require 'mongoose'
_ = require 'underscore'
AttachedFile = require './attached_file'

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

Attachments.virtual('config').get ->
  @parent().schema.attachmentsConfig[@name]

Attachments.virtual('attachedFile').get ->
  @_attachedFile ?=  new AttachedFile @id,
    modelName: @config.modelName or @parent().constructor.modelName
    modelId: @parent().id
    attributeName: @name
    fileName: @fileName
    styles: @config.styles
    s3Headers: @config.s3Headers
    file:
      name: @fileName
      type: @contentType
      path: @file

Attachments.path('contentType').validate (v) ->
  contentTypes = @config.contentType
  return !contentTypes? or (v in contentTypes)
, "acceptable content type"

Attachments.method
  url: (style) ->
    @attachedFile.url(style)

  toObject: (options) ->
    json = mongoose.Model.prototype.toObject.call(@, options)
    if options?.client
      styles = _.extend {original: ''}, @config.styles
      for own style, options of styles
        json[style] = url: @url(style)
    json

Attachments.pre 'save', (next) ->
  return next() unless @file?
  @attachedFile.save (err) =>
    console.log 'saved Attachment', {err}, @file
    unless err?
      @file = null
    next(err)

Attachments.pre 'remove', (next) ->
  # Remove attached file and then remove hook from save in case save is called again
  removeFn = (cb) =>
    @attachedFile.remove cb
    @parent().removePre 'save', removeFn

  @parent().pre 'save', removeFn
  next()

exports = module.exports = (schema, options) ->

  name = options.name
  schema.attachmentsConfig ||= {}
  schema.attachmentsConfig[name] = options

  unless schema.path 'attachments'
    schema.add 'attachments': [ Attachments ]
    schema.method addAttachment: (name, value) ->
      if value.path? # It's a file
        @attachments.push
          name: name
          fileName: value.name
          contentType: value.type
          file: value.path
      else
        value.name = name
        @attachments.push value

    # Remove all attached files when model is removed
    schema.pre 'remove', (next) ->
      removes = @attachments.map (attachment) ->
        (cb) -> attachment.attachedFile.remove cb
      async.parallel removes, next

  schema.virtual(name).get ->
    if options.collection
      return (att for att in @attachments when att.name == name )
    _(@attachments).find (a) -> a.name == name

  schema.virtual(name).set (value) ->
    if options.collection
      throw new Error("Attachment value must be an array when collection=true. Add attachments with model.addAttachment(name, value).") unless value.forEach?
      att.remove() for att in @get(name)
      @addAttachment(name, v) for v in value
    else
      (existing = @get(name)) and existing.remove()
      @addAttachment name, value if value? # Setting to null removes attachment

    # Force $set for attachments to avoid https://jira.mongodb.org/browse/SERVER-1050
    @attachments = @attachments[0..-1]
    @markModified('attachments')

  # Validate attachments presence
  if options.required
    schema.pre 'validate', (next) ->
      value = @get(name)
      return next() if options.collection and value.length > 0 or value?
      @invalidate name, 'required'
      next()

exports.Attachment = mongoose.model 'Attachment', Attachments
