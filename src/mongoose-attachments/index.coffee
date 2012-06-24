module.exports =
  configure: (config) ->
    require('./storage').configure(config.storage)
  Processor: require './processor'
  Attachment: require './attachment'
  hasAttachment: require './plugin'
