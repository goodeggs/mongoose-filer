require './support/spec_helper'
attachments = require '..'
{ AttachedFile, Processor } = attachments

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

    it "bootstraps storage", ->
      expect(require('../lib/mongoose-filer/storage').prototype.filePath).toBeTruthy()

    describe "AttachedFile", ->
      attachment = null

      beforeEach ->
        attachment = new AttachedFile '123', file: file, modelName: "Post", modelId: '456', attributeName: 'photo', styles: styles

      it "has urls for styles", ->
        expect(attachment.url 'thumb').toEqual "http://localhost:3000/uploads/post/456/photo/123_thumb.jpg"



      it "writes to and removes from filesystem paths", (done) ->
        attachment.save (err) ->
          return done(err) if err?
          expect(attachment.store.filePath 'original').exists()
          expect(attachment.store.filePath 'thumb').exists()
          expect(attachment.store.filePath 'croppable').exists()
          expect(attachment.store.filePath 'big').exists()

          attachment.remove (err) ->
            return done(err) if err?
            expect(attachment.store.filePath 'original').not.exists()
            done()

  describe "when configured for s3 storage", ->

    beforeEach ->
      attachments.configure
        storage:
          s3:
            access_key_id: "ACCESS_KEY_ID"
            secret_access_key: "SECRET_ACCESS_KEY"
            bucket: "mongoose_attachments_test"

    describe "AttachedFile", ->
      attachment = null

      beforeEach ->
        attachment = new AttachedFile '123', file: file, modelName: "Post", attributeName: 'photo', styles: styles

      describe "save", ->
        putFile = null
        beforeEach ->
          putFile = spyOn(KnoxClient.prototype, 'putFile').andCallback(null, {statusCode: 204})

        it "writes to s3", (done) ->
          attachment.save (err) ->
            expect(putFile).toHaveBeenCalled()
            expect(putFile.callCount).toEqual 4
            expect(putFile.mostRecentCall.args[2]['Content-Type']).toEqual "image/jpeg"
            done()

      describe "remove", ->
        deleteFile = null
        beforeEach ->
          deleteFile = spyOn(KnoxClient.prototype, 'deleteFile').andCallback(null, {statusCode: 204})

        it "writes to s3", (done) ->
          attachment.remove (err) ->
            expect(deleteFile).toHaveBeenCalled()
            expect(deleteFile.callCount).toEqual 4
            done()
