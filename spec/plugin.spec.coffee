require './support/spec_helper'
mongoose = require 'mongoose'
{AttachedFile, Processor, hasAttachment} = attachments = require '../src/mongoose-filer'

beforeAll ->
  mongoose.connect 'mongodb://localhost/mongoose-filer_test'
afterAll ->
  mongoose.disconnect()

getOrDefineModel = (name, schema) ->
  try
    return mongoose.model(name)
  catch e
    mongoose.model name, schema

file =
  name: "clark_summit.jpg"
  path: "./spec/clark_summit.jpg"
  type: 'image/jpeg'

describe "Mongoose plugin", ->

  beforeEach ->
    attachments.configure
      baseUrl: 'http://localhost:3000',
      storage:
        filesystem:
          dir: './tmp'
    spyOn(AttachedFile.prototype, 'save').andCallback()

  describe "Attachment model", ->
    it "has non-persistant file path", ->
      attachment = new hasAttachment.Attachment
        name: 'avatar'
        fileName: file.name
        contentType: file.type
        file: file.path
      expect(attachment.file).toEqual file.path

  describe "Model with image attachment", ->
    {schema, Model} = {}

    beforeEach ->
      schema = new mongoose.Schema
      schema.plugin hasAttachment,
        name: 'avatar'
        styles: { thumb: '100x100^' }
        contentType: [ 'image/jpeg', 'image/png', 'image/gif' ]
        s3Headers: { 'Cache-Control': 'max-age=3600' }
      Model = getOrDefineModel 'OneAttachment', schema

    describe 'with a model instance', ->
      {model} = {}

      beforeEach ->
        model = new Model()

      describe "with attachment but no file", ->
        beforeEach (done) ->
          model.avatar =
            fileName: file.name
            contentType: file.type
          model.save (done)

        it "has saved attachment", ->
          expect(model.avatar.fileName).toEqual file.name
          expect(model.avatar.url('thumb')).toBeTruthy()

        it "propagates s3Headers config", ->
          expect(model.avatar.attachedFile.s3Headers['Cache-Control']).toEqual 'max-age=3600'

        it "removes attachment", (done) ->
          model.avatar.remove()
          model.save (err) ->
            expect(model.avatar).toBeFalsy()
            done(err)

      describe "with attachment as file", ->

        it "creates attachment from file", ->
          model.avatar = file
          expect(model.attachments.length).toEqual 1
          expect(model.avatar.name).toEqual 'avatar'
          expect(model.avatar.fileName).toEqual file.name
          expect(model.avatar.contentType).toEqual file.type
          expect(model.avatar.file).toEqual file.path
          expect(model.avatar.url('thumb')).toEqual "http://localhost:3000/one_attachment/#{model.id}/avatar/#{model.avatar.id}_thumb.jpg"

        it "validates content type and passes", (done) ->
          model.avatar = file
          model.save (err) ->
            expect(AttachedFile.prototype.save).toHaveBeenCalled()
            done(err)

        it "validates content type and fails", (done) ->
          model.avatar =
            name: file.name
            path: file.path
            type: 'application/octet-stream'

          model.save (err) ->
            # TODO: error should be at avatar.contentType
            expect(err?.errors?['attachments.0.contentType']).toBeTruthy()
            expect(AttachedFile.prototype.save).not.toHaveBeenCalled()
            done()

      describe "with saved attached file", ->
        beforeEach (done) ->
          model.avatar = file
          model.save(done)

        it 'clears local file path to prevent duplicate uploads', ->
          expect(model.avatar.file).toBeNull()

        describe "when updating", ->
          file2 =
            name: 'hen_house.jpg'
            path: './spec/hen_house.jpg'
            type: 'image/jpeg'

          it "updates attachment", (done) ->
            model.avatar = file2
            model.save done

        describe "#toJSON", ->
          it "includes attachments urls in json", ->
            json = JSON.parse JSON.stringify model.toJSON(client: true)
            expect(json.attachments[0].original.url).toEqual model.avatar.url('original')
            expect(json.attachments[0].thumb.url).toEqual model.avatar.url('thumb')

        describe "model#remove", ->
          beforeEach ->
            spyOn(AttachedFile.prototype, 'remove').andCallback()

          it "removes attached file", (done) ->
            model.remove (err) ->
              expect(AttachedFile.prototype.remove).toHaveBeenCalled()
              done(err)

        describe "Attachment#remove", ->
          beforeEach ->
            spyOn(AttachedFile.prototype, 'remove').andCallback()

          it "removes attached file", (done) ->
            model.avatar.remove()
            model.save (err) ->
              expect(AttachedFile.prototype.remove).toHaveBeenCalled()
              done(err)

          it "removes when set to null", (done) ->
            model.avatar = null
            model.save (err) ->
              expect(AttachedFile.prototype.remove).toHaveBeenCalled()
              done(err)

      # Mongoose 3.3.x and earlier, this behavior was not supported
      describe 'with file passed to initializer', ->

        it "Model#save saves attachment", (done) ->
          model = new Model avatar: file
          model.save (err) ->
            expect(AttachedFile.prototype.save).toHaveBeenCalled()
            done(err)

        it "Model.create saves attachment", (done) ->
          Model.create avatar: file, (err) ->
            expect(AttachedFile.prototype.save).toHaveBeenCalled()
            done(err)

    describe "with another attachment", ->
      beforeEach ->
        schema.plugin hasAttachment,
          name: 'anything'
        Model = getOrDefineModel 'TwoAttachment', schema

      it "does not validate content type", (done) ->
        model = new Model()
        model.anything =
          name: file.name
          path: file.path
          contentType: 'application/octet-stream'
        model.save done

      describe "with two unsaved attached files", ->
        model = null

        beforeEach ->
          model = new Model()
          model.avatar = file
          model.anything =
            name: file.name
            path: file.path
            contentType: 'application/octet-stream'

        it "has multiple attachments", ->
          expect(model.attachments.length).toEqual(2)
          model.avatar = file
          expect(model.attachments.length).toEqual(2)

        it "saves two new attachments", (done) ->
          model.save (err) ->
            expect(AttachedFile.prototype.save.callCount).toEqual 2
            done(err)

        it "model#remove removes both attached files exactly once", (done) ->
          spyOn(model.avatar.attachedFile, 'remove').andCallback()
          spyOn(model.anything.attachedFile, 'remove').andCallback()
          model.remove (err) ->
            expect(model.anything.attachedFile.remove.callCount).toEqual 1
            expect(model.avatar.attachedFile.remove.callCount).toEqual 1
            done(err)

  describe "with required attachment", ->
    schema = null
    Model = null

    beforeEach ->
      schema = new mongoose.Schema
        name: type: String, required: true
      schema.plugin hasAttachment,
        name: 'avatar'
        styles: { thumb: '100x100^' }
        contentType: [ 'image/jpeg', 'image/png', 'image/gif' ]
        required: true
      Model = getOrDefineModel 'RequiredAttachment', schema

    it "validates required", (done) ->
      Model.create {}, (err) ->
        expect(err).toBeTruthy()
        expect(err.errors.name).toBeTruthy()
        expect(err.errors.avatar).toBeTruthy()
        done()

  describe "with attachment on embedded document", ->
    Parent = null
    Child = null

    beforeEach ->
      childSchema = new mongoose.Schema
      childSchema.plugin hasAttachment,
        name: 'avatar'
        modelName: 'Child'
        styles: { thumb: '100x100^' }
        contentType: [ 'image/jpeg', 'image/png', 'image/gif' ]
      Child = getOrDefineModel 'Child', childSchema
      parentSchema = new mongoose.Schema
        children: [ childSchema ]
      Parent = getOrDefineModel 'Parent', parentSchema

    it "saves attachment on parent create", (done) ->
      child = new Child()
      child.avatar = file
      Parent.create children: [ child ], (err, parent) ->
        expect(AttachedFile.prototype.save).toHaveBeenCalled()
        done(err)

    it "saves attachment on parent save", (done) ->
      parent = new Parent children: [ new Child() ]
      parent.children[0].avatar = file
      parent.save (err) ->
        expect(AttachedFile.prototype.save).toHaveBeenCalled()
        done(err)

    describe "with existing model", ->
      parent = null
      beforeEach (done) ->
        parent = new Parent children: [ new Child() ]
        parent.save done

      it "updates attachment", (done) ->
        parent.children[0].avatar = file
        parent.save (err) ->
          expect(AttachedFile.prototype.save).toHaveBeenCalled()
          done(err)

      it "updates reloaded model", (done) ->
        Parent.findById parent, (err, reloaded) ->
          reloaded.children[0].avatar = file
          reloaded.save (err) ->
            expect(AttachedFile.prototype.save).toHaveBeenCalled()
            done(err)

  describe "with attachment attribute option collection=true", ->
    schema = null
    Model = null
    file2 =
      name: "hen_house.jpg"
      path: "./spec/hen_house.jpg"
      type: 'image/png'

    beforeEach ->
      schema = new mongoose.Schema
      schema.plugin hasAttachment,
        name: 'avatars'
        styles: { thumb: '100x100^' }
        contentType: [ 'image/jpeg', 'image/png', 'image/gif' ]
        collection: true
      Model = getOrDefineModel 'AttachmentCollection', schema

    it "has multiple attachments", (done) ->
      model = new Model()
      model.avatars = [file, file2]
      model.save (err) ->
        expect(AttachedFile.prototype.save.callCount).toEqual 2
        expect(model.avatars[0].fileName).toEqual(file.name)
        expect(model.avatars[1].fileName).toEqual(file2.name)
        done(err)

