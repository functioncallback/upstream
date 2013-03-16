path = require 'path'
express = require 'express'
passport = require 'passport'
assets = require 'connect-assets'
stylus = require 'stylus'
jade = require 'jade'
nib = require 'nib'

exports.init = (sessionStore, cookieParser) ->
  app = express()

  app.configure () ->
    app.set 'port', process.env.PORT || 7000
    app.set 'views', path.resolve('views')
    app.set 'view engine', 'jade'

    app.use express.logger()
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use cookieParser
    app.use express.session(store: sessionStore)
    app.use express.static path.resolve('assets/static')
    app.use passport.initialize()
    app.use passport.session()
    app.use app.router
    app.use assets()

  app.configure 'development', () ->
    app.use express.errorHandler()

  app.configure 'production', () ->

  app
