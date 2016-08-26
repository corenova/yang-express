# socket.io (websockets) feature interface module
#

module.exports = (opts={}, done=->) ->
  @once 'running', (server) ->
    console.info "[websocket] binding to server"
    app = this
    io = (require 'socket.io') server
    io.on 'connection', (socket) ->
      console.log '[websocket] User connected. socket id %s', socket.id
      keys = app.get('links').map (link) -> link._id
      socket.on 'join', (rooms...) ->
        rooms = [].concat rooms...
        console.log '[socket:%s] Joining %s', socket.id, rooms
        socket.join room for room in rooms when room in ids
      socket.on 'leave', (rooms...) ->
        rooms = [].concat rooms...
        console.log '[socket:%s] Leaving %s', socket.id, rooms
        socket.leave room for room in rooms
      socket.on 'knock', ->
        console.log '[socket:%s] Knocking for rooms', socket.id
        keys = app.get('links').map (link) -> link._id
        socket.emit 'rooms', keys
      socket.emit 'rooms', keys

      # TODO: this should be bound to each room?
      socket.on 'fetch', ->
        console.log "[websocket] User requested fetch"
        console.log arguments
        console.log this

    # setup initial update sync notifications
    @get('stores').forEach (store) ->
      store.on 'update', (prop) -> io.to(@name).emit 'sync', data: prop.path

    # # watch for link/unlink activity
    # @on 'link', (id, model) ->
    #   model.on 'update', (prop) -> io.to(@_id).emit 'sync', data: prop.path
    # @on 'unlink', (id, model) ->
    #   io.to(model._id).emit 'disconnect'
      
    done io

