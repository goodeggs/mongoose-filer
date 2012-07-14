fs = require 'fs'
require './before_after_all_helper'

jasmine.Spy::andCallback = (err, result) ->
  @andCallFake (args...) ->
    cb = args.pop()
    process.nextTick ->
      cb(err, result)

beforeEach ->
  @addMatchers
    exists: ->
      @message = -> "Expected #{@actual} to exist on the filesystem"
      fs.existsSync @actual
