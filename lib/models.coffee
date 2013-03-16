slug = require 'slug'
_ = require 'underscore'
mongoose = require 'mongoose'
db = mongoose.createConnection config.mongo.url
ObjectId = mongoose.Schema.Types.ObjectId
definitions = {}
schemas = {}

exports.init = (callback) ->
  db.on 'error', -> callback 'error connecting to mongodb'
  db.once 'open', -> bootstrap() and callback()

def = (name, schema) ->
  definitions[name] = _.extend({}, schema, timestamp)
  schemas[name] = new mongoose.Schema definitions[name]
  global[name] = db.model name, schemas[name]
  schemas[name].pre 'save', (next) ->
    @updatedAt = Date.now()
    next()

cache = (withinClassName, settings) ->
  for key, mapping of settings
    for className, attributes of mapping
      schemas[withinClassName].pre 'save', (next) ->
        global[className].findOne { _id: this["#{key}Id"] }, (err, model) =>
          this[key] = _.pick(model, attributes) if model and attributes
          next()

extend = (base, definition) ->
  _.extend _.clone(definitions[base]), definition

timestamp =
  createdAt: { type: Date, default: Date.now }
  updatedAt: { type: Date }

bootstrap = ->
  def 'User',
    auth: { type: Object, required: true }
    name: { type: String, required: true }
    givenName: { type: String, required: true }
    familyName: { type: String, required: true }
    email: { type: String, required: true }
    picture: { type: String, default: '/img/avatar.png' }
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

  cache 'Stream', owner: User: ['name', 'picture', 'updatedAt']
  cache 'Message', from: User: ['name', 'picture', 'updatedAt']
  cache 'Message', to: Stream: ['name', 'slug', 'updatedAt']
  cache 'PrivateMessage', from: User: ['name', 'picture', 'updatedAt']
  cache 'PrivateMessage', to: User: ['name', 'picture', 'updatedAt']
