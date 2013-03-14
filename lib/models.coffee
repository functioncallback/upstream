slug = require 'slug'
_ = require 'underscore'
mongoose = require 'mongoose'
db = mongoose.createConnection config.mongo.url
ObjectId = mongoose.Schema.Types.ObjectId
schemas = definitions: {}

exports.init = (callback) ->
  db.on 'error', -> callback 'error connecting to mongodb'
  db.once 'open', -> bootstrap() && callback()

def = (name, schema) ->
  schemas.definitions[name] = _.extend({}, base, schema)
  schemas[name] = new mongoose.Schema schemas.definitions[name]
  global[name] = db.model name, schemas[name]
  schemas[name].pre 'save', (next) ->
    @updatedAt = Date.now()
    next()

extend = (base, definition) ->
  _.extend _.clone(schemas.definitions[base]), definition

minify = (o) ->
  _.pick(o, 'name', 'slug', 'picture', 'updatedAt')

base =
  createdAt: { type: Date, default: Date.now }
  updatedAt: { type: Date }

bootstrap = ->
  def 'User',
    auth: { type: Object, required: true }
    name: { type: String, required: true }
    givenName: { type: String, required: true }
    familyName: { type: String, required: true }
    email: { type: String, required: true }
    picture: String
    gender: String

  def 'Stream',
    name: { type: String, required: true }
    slug: { type: String, required: true, unique: true }
    ownerId: { type: ObjectId, ref: 'User', required: true }
    owner: { type: Object, required: true }

  def 'Message',
    body: { type: String, required: true }
    fromId: { type: ObjectId, ref: 'User', required: true }
    toId: { type: ObjectId, ref: 'Stream', required: true }
    from: { type: Object, required: true }
    to: { type: Object, required: true }

  def 'PrivateMessage', extend 'Message',
    toId: { type: ObjectId, ref: 'User', required: true }

  schemas.Stream.pre 'validate', (next) ->
    @slug = slug(@name).toLowerCase().match(/\w|-/g).join('') if @name
    next()

  schemas.Stream.pre 'save', (next) ->
    User.findOne { _id: @ownerId }, (err, user) =>
      @owner = minify(user)
      next()

  schemas.Message.pre 'save', (next) ->
    User.findOne { _id: @fromId }, (err, user) =>
      @from = minify(user)
      next()

  schemas.Message.pre 'save', (next) ->
    Stream.findOne { _id: @toId }, (err, stream) =>
      @to = minify(stream)
      next()

  schemas.PrivateMessage.pre 'save', (next) ->
    User.findOne { _id: @fromId }, (err, user) =>
      @from = minify(user)
      next()

  schemas.PrivateMessage.pre 'save', (next) ->
    User.findOne { _id: @toId }, (err, user) =>
      @to = minify(user)
      next()
