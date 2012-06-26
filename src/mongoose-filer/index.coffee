module.exports =
  configure: (config) ->
    require('./storage').configure(config)
  Processor: require './processor'
  AttachedFile: require './attached_file'
  hasAttachment: require './plugin'
