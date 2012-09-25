require './support/spec_helper'
{AttachedFile} = require '..'

describe "AttachedFile", ->
  attachedFile = null

  beforeEach ->
    attachedFile = new AttachedFile '123',
      modelName: 'model'
      modelId: '456'
      attributeName: 'attribute'
      fileName: 'test.jpg'
      styles: ['standard']
      file:
        name: 'test.jpg'
        type: 'image/jpeg'
        path: './spec/does_not_exist.jpg'

  describe "save", (next) ->
    describe 'with unresolvable file path', ->
      it 'errors', (done) ->
        attachedFile.save (err) ->
          expect(err).toMatch /file not found/
          done()
