attachments = require '../lib/attachments'

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

  describe "configuration", ->

    it "initializes", ->
      configured = attachments(config)
      expect(configured.Attachment).toBeTruthy()


