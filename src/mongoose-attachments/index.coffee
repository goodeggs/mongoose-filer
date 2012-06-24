module.exports =
  configure: (config) ->
    require('./storage').configure(config)
  Processor: require './processor'
  Attachment: require './attachment'
  hasAttachment: require './plugin'
