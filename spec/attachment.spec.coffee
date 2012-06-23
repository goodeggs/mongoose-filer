fs = require 'fs'

describe "attachments", ->
  attachments = null

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
      file =
        name: "clark_summit.jpg"
        path: "./spec/clark_summit.jpg"
        type: 'image/jpeg'

      beforeEach ->
        processor = new attachments.Processor file, id: '123', prefix: "photos", styles:
          thumb: '100x100^'
          croppable: '600x600>'
          big: '1000x1000>'

      it "defines conversions", ->
        conversions = processor.conversions()
        expect(conversions.length).toEqual 3
        expect(conversions[0].args).toEqual [ './spec/clark_summit.jpg', '-resize', '100x100^', '-gravity', 'center', '-extent', '100x100', './tmp/photos/123/thumb/clark_summit.jpg' ]

      it "creates all sizes", (done) ->
        processor.convert (err) ->
          expect(err).toBeFalsy()
          expect(fs.readdirSync(processor.dir('thumb')).length).toEqual 1
          expect(fs.readdirSync(processor.dir('croppable')).length).toEqual 1
          expect(fs.readdirSync(processor.dir('big')).length).toEqual 1
          done()

      it "dispatches convert events", (done) ->
        count = 0
        processor.on 'convert', (result) ->
          count++
        processor.convert (err) ->
          expect(count).toEqual 3
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

    describe "Processor", ->
      processor = null
      file =
        name: "clark_summit.jpg"
        path: "./spec/clark_summit.jpg"
        type: 'image/jpeg'

      beforeEach ->
        processor = new attachments.Processor file, id: '123', prefix: "photos", styles:
          thumb: '100x100^'
          croppable: '600x600>'
          big: '1000x1000>'

#      it "defines conversions", ->
#        conversions = processor.conversions()
#        expect(conversions.length).toEqual 3
#        expect(conversions[0].args).toEqual [ './spec/clark_summit.jpg', '-resize', '100x100^', '-gravity', 'center', '-extent', '100x100', './tmp/photos/123/thumb/clark_summit.jpg' ]
#
#      it "creates all sizes", (done) ->
#        processor.convert (err) ->
#          expect(err).toBeFalsy()
#          expect(fs.readdirSync(processor.dir('thumb')).length).toEqual 1
#          expect(fs.readdirSync(processor.dir('croppable')).length).toEqual 1
#          expect(fs.readdirSync(processor.dir('big')).length).toEqual 1
#          done()

