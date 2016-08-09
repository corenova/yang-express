# socket.io (websockets) feature interface module
#

module.exports = (app) -> app.on 'run', (server) ->
  { models, data } = app.locals
  console.info "[socket.io] binding #{models.length} models"
  io = (require 'socket.io') server
  io.on 'connection', (socket) ->
    rooms = models.map (model) -> socket.join model.tag

  # # watch core and send events
  # @on 'merge', (cores...) ->
  #   io.to('yang-forge-core')
  #     .emit 'infuse', cores: cores.map (x) -> x.dump()
