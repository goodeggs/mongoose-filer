require './support/spec_helper'
attachments = require '..'

fs = require 'fs'
path = require 'path'
KnoxClient = require 'knox'

describe "attachments", ->
  file =
    name: "clark_summit.jpg"
    path: "./spec/clark_summit.jpg"
    type: 'image/jpeg'
  styles =
    thumb: '100x100^'
    croppable: '600x600>'
    big: '1000x1000>'

  describe "when configured for dir storage", ->

    beforeEach ->
      attachments.configure
        baseUrl: 'http://localhost:3000/uploads'
        storage:
          filesystem:
            dir: "./tmp"

    it "initializes", ->
      expect(attachments.Processor).toBeTruthy()

    describe "Attachment", ->
      attachment = null

      beforeEach ->
        attachment = new attachments.Attachment '123', file: file, modelName: "Post", attributeName: 'photo', styles: styles

      it "has urls for styles", ->
        expect(attachment.url 'thumb').toEqual "http://localhost:3000/uploads/post/photo/123/thumb/clark_summit.jpg"

      it "writes to filesystem paths", (done) ->
        attachment.save (err) ->
          expect(err).toBeFalsy()
          expect(attachment.store.filePath 'original').exists()
          expect(attachment.store.filePath 'thumb').exists()
          expect(attachment.store.filePath 'croppable').exists()
          expect(attachment.store.filePath 'big').exists()
          done()

  describe "when configured for s3 storage", ->

    beforeEach ->
      attachments.configure
        storage:
          s3:
            access_key_id: "ACCESS_KEY_ID"
            secret_access_key: "SECRET_ACCESS_KEY"
            bucket: "mongoose_attachments_test"

    describe "Attachment", ->
      attachment = null
      putFile = null

      beforeEach ->
        attachment = new attachments.Attachment '123', file: file, modelName: "Post", attributeName: 'photo', styles: styles

      describe "writing", ->
        beforeEach ->
          putFile = spyOn(KnoxClient.prototype, 'putFile').andCallback()

        it "writes to s3", (done) ->
          attachment.save (err) ->
            expect(putFile).toHaveBeenCalled()
            expect(putFile.mostRecentCall.args[2]['Content-Type']).toEqual "image/jpeg"
            done()
