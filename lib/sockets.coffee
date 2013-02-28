#https://github.com/LearnBoost/socket.io/wiki/Rooms
_ = require 'underscore'

exports.init = (io, sessionSockets) ->
  data = online: {}, sockets: {}
  io.set 'log level', 2

  sessionSockets.on 'connection', (err, socket, session) ->
    return unless valid(err, socket, session)

    data.online[session.user._id] = session.user
    data.sockets[session.user._id] = socket
    socket.broadcast.emit 'signed:in', session.user
    socket.emit 'online', data.online

    socket.on 'disconnect', ->
      delete data.online[session.user._id]
      delete data.sockets[session.user._id]
      io.sockets.emit 'signed:off', session.user._id

    socket.on 'post:stream', (stream) ->
      console.log 'post:stream', stream
      return unless stream
      stream.ownerId = session.user._id
      new Stream(stream).save (err, saved) ->
        console.log err, saved
        socket.emit 'err', friendly(err) if err
        if saved
          io.sockets.emit 'reload:streams'
          namespace(saved)

    socket.on 'put:stream', (stream) ->
      console.log 'put:stream', stream
      return unless stream?._id and stream.name
      Stream.findOne { _id: stream._id }, (findErr, found) ->
        console.log 'findErr', findErr if findErr
        return unless found
        found.name = stream.name
        found.save (updateErr, updated) ->
          console.log updateErr, updated
          socket.emit 'err', friendly(updateErr) if updateErr
          io.sockets.emit 'put:stream', updated if updated
          io.sockets.emit 'reload:streams' if updated

    socket.on 'delete:stream', (id) ->
      console.log 'delete:stream', id
      return unless id
      Stream.remove { _id: id }, (err) ->
        console.log 'err', err if err
        io.sockets.emit 'delete:stream', id unless err
        io.sockets.emit 'reload:streams' unless err

    socket.on 'post:private', (privateMessage) ->
      console.log 'post:private', privateMessage
      return unless privateMessage
      privateMessage.fromId = session.user._id
      new PrivateMessage(privateMessage).save (err, saved) ->
        console.log err, saved
        socket.emit 'err', friendly(err) if err
        if saved
          data.sockets[saved.to._id]?.emit 'post:private', saved
          socket.emit 'post:private', saved

  Stream.find (err, streams) ->
    namespace(stream) for stream in streams

  namespace = (stream) ->
    sessionSockets.of("/stream/#{stream._id}").on 'connection', (err, socket, session) ->
      return unless valid(err, socket, session)

      socket.broadcast.emit 'join', session.user
      socket.on 'disconnect', ->
        socket.broadcast.emit 'leave', session.user._id

      socket.on 'post:message', (message) ->
        console.log 'post:message', message
        return unless message
        message.fromId = session.user._id
        new Message(message).save (err, saved) ->
          console.log err, saved
          socket.emit 'err', friendly(err) if err
          if saved
            socket.broadcast.emit 'post:message', saved
            socket.emit 'post:message', saved

valid = (err, socket, session) ->
  invalid = err || (socket && (!session || !session.user))
  if invalid
    socket.emit 'err', if err then 'Socket connection failed' else 'Authentication required'
    socket.disconnect() if socket
  return not invalid

friendly = (err) ->
  return 'Name already in use' if err?.err?.match /duplicate\skey/
  return 'Name is required' if err?.errors?.name?.type == 'required'
  return 'Message is required' if err?.errors?.body?.type == 'required'
