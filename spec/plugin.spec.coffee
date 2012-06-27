require './support/spec_helper'
mongoose = require 'mongoose'
attachments = require '..'
{AttachedFile, hasAttachment} = attachments

# TODO: remove files on Attachment#remove

beforeAll ->
  mongoose.connect 'mongodb://localhost/mongoose-filer_test'
afterAll ->
  mongoose.disconnect()

describe "Mongoose plugin", ->
  file =
    name: "clark_summit.jpg"
    path: "./spec/clark_summit.jpg"
    type: 'image/jpeg'

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

  describe "with image attachment", ->
    schema = null
    Model = null

    beforeEach ->
      schema = new mongoose.Schema
      schema.plugin hasAttachment,
        name: 'avatar'
        styles: { thumb: '100x100^' }
        contentType: [ 'image/jpeg', 'image/png', 'image/gif' ]
      Model = mongoose.model 'OneAttachment', schema

    describe 'with model defined', ->
      model = null
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

        it "removes attachment", (done) ->
          model.avatar.remove()
          model.save(done)

      describe "when model is saved", ->

        it "creates attachment from model data without file", (done) ->
          model.avatar =
            fileName: file.name
            contentType: file.type
          model.save (err) ->
            expect(model.avatar.fileName).toEqual file.name
            done(err)

        it "creates attachment from file", ->
          model.avatar = file
          expect(model.attachments.length).toEqual 1
          expect(model.avatar.name).toEqual 'avatar'
          expect(model.avatar.fileName).toEqual file.name
          expect(model.avatar.contentType).toEqual file.type
          expect(model.avatar.file).toEqual file.path
          expect(model.avatar.url('thumb')).toEqual "http://localhost:3000/one_attachment/avatar/#{model.id}/thumb/clark_summit.jpg"

        it "validates content type and passes", (done) ->
          model.avatar = file
          model.save done

        it "validates content type and fails", (done) ->
          model.avatar =
            name: file.name
            path: file.path
            type: 'application/octet-stream'

          model.save (err) ->
            expect(err?.errors?.contentType).toBeTruthy()
            done()

      describe "#toJSON", ->
        beforeEach (done) ->
          model.avatar = file
          model.save(done)

        it "includes attachments urls in json", ->
          json = JSON.parse JSON.stringify model.toJSON(client: true)
          expect(json.attachments[0].original.url).toEqual model.avatar.url('original')
          expect(json.attachments[0].thumb.url).toEqual model.avatar.url('thumb')

      describe "when model is removed", ->
        beforeEach (done) ->
          model.avatar = file
          model.save(done)
          spyOn(AttachedFile.prototype, 'remove').andCallback()

        it "removes attached file", (done) ->
          model.remove (err) ->
            done(err) if err?
            expect(AttachedFile.prototype.remove).toHaveBeenCalled()
            done()

      describe "Attachment#remove", ->
        beforeEach (done) ->
          model.avatar = file
          model.save(done)
          spyOn(AttachedFile.prototype, 'remove').andCallback()

        it "removes attached file", (done) ->
          model.avatar.remove()
          model.save (err) ->
            done(err) if err?
            expect(AttachedFile.prototype.remove).toHaveBeenCalled()
            done()

        it "removes when set to null", (done) ->
          model.avatar = null
          model.save (err) ->
            done(err) if err?
            expect(AttachedFile.prototype.remove).toHaveBeenCalled()
            done()


    describe "with another attachment", ->
      beforeEach ->
        schema.plugin hasAttachment,
          name: 'anything'
        Model = mongoose.model 'TwoAttachment', schema

      it "does not validate content type", (done) ->
        model = new Model()
        model.anything =
          name: file.name
          path: file.path
          contentType: 'application/octet-stream'
        model.save done

      it "has multiple attachments", ->
        model = new Model()
        model.avatar = file
        model.anything =
          name: file.name
          path: file.path
          contentType: 'application/octet-stream'
        expect(model.attachments.length).toEqual(2)

        model.avatar = file
        expect(model.attachments.length).toEqual(2)

      it "saves two new attachments", (done) ->
        model = new Model()
        model.avatar = file
        model.anything =
          name: file.name
          path: file.path
          contentType: 'application/octet-stream'

        model.save (err) ->
          expect(err).toBeFalsy()
          expect(AttachedFile.prototype.save.callCount).toEqual 2
          model.save (err) ->
            expect(AttachedFile.prototype.save.callCount).toEqual 2
            done()

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
      Model = mongoose.model 'RequiredAttachment', schema

    it "validates required", (done) ->
      Model.create {}, (err) ->
        expect(err).toBeTruthy()
        expect(err.errors.name).toBeTruthy()
        expect(err.errors.avatar).toBeTruthy()
        done()








