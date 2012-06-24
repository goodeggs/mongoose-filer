require './support/spec_helper'
mongoose = require 'mongoose'
hasAttachment = require '../lib/mongoose-attachments/plugin'

beforeAll ->
  mongoose.connect 'mongodb://localhost/mongoose-attachments_test'
afterAll ->
  mongoose.disconnect()

describe "Mongoose plugin", ->
  file =
    name: "clark_summit.jpg"
    path: "./spec/clark_summit.jpg"
    type: 'image/jpeg'

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
        styles: { thumb: '100x100^', small: '400x4 00>' }
        contentType: [ 'image/jpeg', 'image/png', 'image/gif' ]
      Model = mongoose.model 'OneAttachment', schema

    describe 'with model defined', ->
      model = null
      beforeEach ->
        model = new Model()

      it "creates attachment from file", ->
        model.avatar = file
        expect(model.attachments.length).toEqual 1
        expect(model.avatar.name).toEqual 'avatar'
        expect(model.avatar.fileName).toEqual file.name
        expect(model.avatar.contentType).toEqual file.type
        expect(model.avatar.file).toEqual file.path

      it "validates content type and passes", (done) ->
        model.avatar = file
        model.save done

      it "validates content type and fails", (done) ->
        model.avatar =
          path: file.path
          type: 'application/octet-stream'

        model.save (err) ->
          expect(err?.errors?.contentType).toBeTruthy()
          done()

    describe "with another attachment", ->
      beforeEach ->
        schema.plugin hasAttachment,
          name: 'anything'
        Model = mongoose.model 'TwoAttachment', schema

      it "does not validate content type", (done) ->
        model = new Model()
        model.anything =
          path: file.path
          contentType: 'application/octet-stream'
        model.save done

      it "has multiple attachments", ->
        model = new Model()
        model.avatar = file
        model.anything =
          path: file.path
          contentType: 'application/octet-stream'
        expect(model.attachments.length).toEqual(2)

        model.avatar = file
        expect(model.attachments.length).toEqual(2)






