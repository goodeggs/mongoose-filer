require './support/spec_helper'
{AttachedFile, Processor} = attachments = require '../src/mongoose-filer'

describe "Processor", ->
  processor = null
  file =
    name: "hen_house.jpg"
    path: "./spec/hen_house.jpg"
    type: 'image/jpeg'
  styles =
    thumb: '100x100^'
    croppable: '600x600>'
    big: '1000x1000>'

  beforeEach ->
    processor = new attachments.Processor file, styles: styles
    processor.on 'error', (err) ->
      jasmine.getEnv().currentSpec.fail(err)

  it "defines conversions", ->
    conversions = processor.conversions()
    expect(conversions.length).toEqual 3
    expect(conversions[0].args[0...-1]).toEqual [
      './spec/hen_house.jpg', '-auto-orient', '-resize', '100x100^', '-gravity', 'center', '-extent', '100x100'
    ]

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
