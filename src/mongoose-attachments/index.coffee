module.exports = (config) ->

  storage = require('./storage')(config.storage)

  Processor: (require('./processor')(config)).Processor
  Attachment: require('./attachment')
