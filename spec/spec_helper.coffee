
jasmine.Spy::andCallback = (err, result) ->
  @andCallFake (args...) ->
    cb = args.pop()
    process.nextTick ->
      cb(err, result)
