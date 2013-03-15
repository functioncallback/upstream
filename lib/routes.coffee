fs = require 'fs'
path = require 'path'
_ = require 'underscore'
v = 1

exports.init = (app, auth) ->

  auth.route(app, requireGuest)

  app.get '/', storeUser, (req, res) ->
    res.render(if bypass || req.isAuthenticated() then 'layout' else 'auth')

  app.get '/signout', requireUser, storeUser, (req, res) ->
    req.logout()
    res.redirect '/'

  build = resource.inject(app).build

  build Stream, 'streams'
  build User, 'users'
  build Message, 'messages'
  build PrivateMessage, 'private-messages'

  app.get /^\/(?!css\/|js\/).*/, requireUser, storeUser, (req, res) ->
    fs.exists path.resolve("views#{req.url}.jade"), (exists) ->
      return res.render(req.url.substr(1)) if exists and req.url.match /partials\//
      res.render('layout')

resource = inject: (app) ->
  build: (Resource, pluralized) ->
    endpoint = "/v#{v}/#{pluralized}"

    app.get endpoint, requireUser, (req, res) ->
      if req.query.fromOrTo
        options = []
        options.push fromId: req.session.user._id, toId: req.query.fromOrTo
        options.push fromId: req.query.fromOrTo, toId: req.session.user._id
        Resource.find().or(options).exec (err, docs) ->
          res.send docs
      else
        Resource.find _.pick(req.query, 'slug', 'toId'), (err, docs) -> res.send docs

    app.get "#{endpoint}/:id", requireUser, (req, res) ->
      Resource.findOne { _id: req.params.id }, (err, doc) ->
        res.send doc

    app.post endpoint, requireUser, (req, res) ->
      console.log 'req.body ------> ', req.body
      doc = new Resource(req.body).save (err) ->
        console.log 'doc ------------> ', doc
        res.send doc

    app.put "#{endpoint}/:id", requireUser, (req, res) ->
      Resource.findOne { _id: req.params.id }, (err, existing) ->
        return if err or not existing
        changes = _.omit(existing, '_id')
        Resource.update { _id: existing._id }, { $set: changes }, (err) ->
          res.send _.extend(existing, changes) unless err

    return this

storeUser = (req, res, next) ->
  req.user = name: 'Wagner Camarao', _id: '512ba2afbee4990000000001', isAdmin: true if bypass
  req.session.user = req.user if bypass
  res.locals.user = req.user if bypass || req.isAuthenticated()
  next()

requireUser = (req, res, next) ->
  return res.redirect '/' unless bypass || req.isAuthenticated()
  next()

requireGuest = (req, res, next) ->
  return res.redirect '/' if bypass || req.isAuthenticated()
  next()

bypass = 0#true
