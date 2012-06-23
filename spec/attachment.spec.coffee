fs = require 'fs'
path = require 'path'

describe "attachments", ->
  attachments = null
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
      config =
        storage:
          dir:
            path: "./tmp"
      attachments = require('../lib/attachments')(config)

    it "initializes", ->
      expect(attachments.Processor).toBeTruthy()

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
          expect(path.existsSync(images['thumb'])).toBeTruthy()
          expect(path.existsSync(images['croppable'])).toBeTruthy()
          expect(path.existsSync(images['big'])).toBeTruthy()
          done()
        processor.convert (err) ->
          expect(err).toBeFalsy()

    describe "Attachment", ->
      attachment = null

      beforeEach ->
        attachment = new attachments.Attachment '123', file: file, prefix: "photos", styles: styles

      it "writes to filesystem paths", (done) ->
        attachment.save (err) ->
          expect(err).toBeFalsy()
          expect(path.existsSync(attachment.path 'thumb')).toBeTruthy()
          expect(path.existsSync(attachment.path 'croppable')).toBeTruthy()
          expect(path.existsSync(attachment.path 'big')).toBeTruthy()
          done()

  describe "when configured for s3 storage", ->

    beforeEach ->
      config =
        storage:
          s3:
            access_key_id: "AKIAJFMXVXFX6LSJIV3A"
            secret_access_key: "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"
            bucket: "mongoose_attachments_test"
      attachments = require('../lib/attachments')(config)

    describe "Attachment", ->
      attachment = null

      beforeEach ->
        attachment = new attachments.Attachment null, file: file, prefix: "photos", styles: styles

      it "writes to s3", (done) ->
        attachment.save done
