path = require 'path'

jasmine.Spy::andCallback = (err, result) ->
  @andCallFake (args...) ->
    cb = args.pop()
    process.nextTick ->
      cb(err, result)

beforeEach ->
  @addMatchers
    exists: ->
      @message = -> "Expected #{@actual} to exist on the filesystem"
      path.existsSync @actual
