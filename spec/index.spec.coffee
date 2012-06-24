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

  describe "Processor", ->
    processor = null

    beforeEach ->
      processor = new attachments.Processor file, styles: styles
      processor.on 'error', (err) ->
        jasmine.getEnv().currentSpec.fail(err)

    it "defines conversions", ->
      conversions = processor.conversions()
      expect(conversions.length).toEqual 3
      expect(conversions[0].args[0...-1]).toEqual [ './spec/clark_summit.jpg', '-resize', '100x100^', '-gravity', 'center', '-extent', '100x100']

    it "creates all sizes", (done) ->
      images = {}
      processor.on 'convert', (result) ->
        images[result.style] = result.file
      processor.on 'done', ->
        expect(images['thumb']).exists()
        expect(images['croppable']).exists()
        expect(images['big']).exists()
        done()
      processor.convert (err) ->
        expect(err).toBeFalsy()

  describe "when configured for dir storage", ->

    beforeEach ->
      attachments.configure
        storage:
          filesystem:
            dir: "./tmp"

    it "initializes", ->
      expect(attachments.Processor).toBeTruthy()

    describe "Attachment", ->
      attachment = null

      beforeEach ->
        attachment = new attachments.Attachment '123', file: file, prefix: "photos", styles: styles

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
        attachment = new attachments.Attachment null, file: file, prefix: "photos", styles: styles

      describe "writing", ->
        beforeEach ->
          putFile = spyOn(KnoxClient.prototype, 'putFile').andCallback()

        it "writes to s3", (done) ->
          attachment.save (err) ->
            expect(putFile).toHaveBeenCalled()
            expect(putFile.mostRecentCall.args[2]['Content-Type']).toEqual "image/jpeg"
            done()
