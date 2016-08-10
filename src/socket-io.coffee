# socket.io (websockets) feature interface module
#

module.exports = (app) -> app.on 'run', (server) ->
  { models, data } = app.locals
  console.info "[socket.io] binding #{models.length} models"
  io = (require 'socket.io') server
  io.on 'connection', (socket) ->
    rooms = models.map (model) -> socket.join model.tag

  # watch models and send events
  models.forEach (model) ->
    model.on 'changed', (changes...) ->
      io.to(model.tag).emit 'changed'
