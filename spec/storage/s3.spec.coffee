require '../support/spec_helper'
withStorage = require '../../src/mongoose-filer/storage/s3'
knox = require 'knox'

describe 's3', ->
  TestStorage = knoxClient = null

  beforeEach ->
    knoxClient = jasmine.createSpyObj('knoxClient', ['putFile', 'deleteFile'])
    knoxClient.putFile.andCallback(null, {statusCode: 200})
    knoxClient.deleteFile.andCallback(null, {statusCode: 204})
    spyOn(knox, 'createClient').andReturn(knoxClient)
    TestStorage = (->)
    TestStorage::path = (style) -> "/#{style}.ext"

  it 'creates a knox client', ->
    withStorage TestStorage,
      access_key_id: 'aki'
      secret_access_key: 'sak'
      bucket: 'b'

    expect(knox.createClient).toHaveBeenCalled()
    args = knox.createClient.mostRecentCall.args
    expect(args[0].key).toEqual 'aki'
    expect(args[0].secret).toEqual 'sak'
    expect(args[0].bucket).toEqual 'b'

  it 'defines write and delete', ->
    withStorage TestStorage, {}
    expect(TestStorage::write).toBeDefined()
    expect(TestStorage::delete).toBeDefined()

  describe '#write', ->

    it 'works', (next) ->
      withStorage TestStorage,
        s3Headers:
          'Cache-Control': 'max-age: 3600, public'
          'X-Foo': 'default'
      store = new TestStorage()
      store.attachedFile =
        s3Headers:
          'X-Foo': 'file'
        file:
          type: 'image/png'

      store.write 'original', '/path/to/file.png', ->
        expect(knoxClient.putFile).toHaveBeenCalled()
        args = knoxClient.putFile.mostRecentCall.args
        expect(args[0]).toEqual '/path/to/file.png'
        expect(args[1]).toEqual '/original.ext'
        headers = args[2]
        expect(headers['Cache-Control']).toEqual 'max-age: 3600, public'
        expect(headers['X-Foo']).toEqual 'file'
        expect(headers['Content-Type']).toEqual 'image/png'
        next()

    it 'returns an error for a non successful response code', (next) ->
      withStorage TestStorage,
        s3Headers:
          'Cache-Control': 'max-age: 3600, public'
          'X-Foo': 'default'
      store = new TestStorage()
      store.attachedFile =
        s3Headers:
          'X-Foo': 'file'
        file:
          type: 'image/png'

      knoxClient.putFile.andCallback(null, {statusCode: 403})

      store.write 'original', '/path/to/file.png', (err) ->
        expect(knoxClient.putFile).toHaveBeenCalled()
        expect(err.message).toMatch '403'
        next()


  describe '#delete', ->

    it 'works', (next) ->
      withStorage TestStorage, {}
      store = new TestStorage()

      store.delete 'original', ->
        expect(knoxClient.deleteFile).toHaveBeenCalled()
        args = knoxClient.deleteFile.mostRecentCall.args
        expect(args[0]).toEqual '/original.ext'
        next()

    it 'fails for a non 204 response', (next) ->
      withStorage TestStorage, {}
      store = new TestStorage()

      knoxClient.deleteFile.andCallback(null, {statusCode: 403})

      store.delete 'original', (err) ->
        expect(knoxClient.deleteFile).toHaveBeenCalled()
        expect(err.message).toMatch '403'
        next()

