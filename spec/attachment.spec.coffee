fs = require 'fs'

config =
  prefix: 'photos'
  storage:
    dir:
      path: "./tmp"

describe "attachments", ->
  attachments = null

  describe "when configured for dir storage", ->

    beforeEach ->
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
        processor = new attachments.Processor file, id: '123', styles:
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


