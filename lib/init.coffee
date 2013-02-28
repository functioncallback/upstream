r = (lib) -> require path.resolve "lib/#{lib}"

express = require 'express'
socketIO = require 'socket.io'
http = require 'http'
path = require 'path'
sockets = r 'sockets'
routes = r 'routes'
models = r 'models'
auth = r 'auth'

models.init (err) ->
  return console.error `"\033[0;31m"` + err + `'\033[0m'` if err

  MemoryStore = require('connect').middleware.session.MemoryStore
  SessionSockets = require 'session.socket.io'

  sessionStore = new MemoryStore
  cookieParser = express.cookieParser 'foo'
  app = r('app').init sessionStore, cookieParser
  server = http.createServer app
  io = socketIO.listen server

  auth.init io.sockets
  routes.init app, auth
  sockets.init io, new SessionSockets io, sessionStore, cookieParser

  server.listen app.get('port'), ->
    console.log "Listening on #{app.get('port')}"
