

config =
  prefix: 'photos'
  storage:
    dir:
      path: "/tmp/mongoose-attachments.spec"
  styles:
    thumb: '100x100^'
    croppable: '600x600>'
    big: '1000x1000>'

describe "attachments", ->

  describe "when configured for dir storage", ->
    attachments = null

    beforeEach ->
      attachments = require('../lib/attachments')(config)

    it "initializes", ->
      expect(attachments.Attachment).toBeTruthy()

    describe "Attachment", ->
      attachment = null
      file =
        name: "clark_summit.jpg"
        path: "./clark_summit.jpg"
        type: 'image/jpeg'

      beforeEach ->
        attachment = new attachments.Attachment file, id: '123'

      it "defines conversions", ->
        conversions = attachment.conversions()
        expect(conversions.length).toEqual 3
        expect(conversions[0].args).toEqual [ './clark_summit.jpg', '-resize', '100x100^', '-gravity', 'center', '-extent', '100x100', '/tmp/mongoose-attachments.spec/photos/123/thumb/clark_summit.jpg' ]


