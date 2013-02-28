path = require 'path'
passport = require 'passport'
keys = require path.resolve "config/auth.keys"
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
_ = require 'underscore'

exports.init = (sockets) ->

  passport.use new GoogleStrategy keys.google, (accessToken, refreshToken, profile, done) ->
    process.nextTick () ->
      User.findOne { auth: googleId: profile.id }, (err, existing) ->
        return done(err) if err

        if existing
          changes = _.pick(existing, 'name', 'familyName', 'givenName', 'email', 'picture', 'gender')
          User.update { _id: existing._id }, { $set: changes }, (err) ->
            return done(err) if err
            sockets.emit 'reload:users'
            done(null, _.extend(existing, changes))

        else
          new User({
            auth: googleId: profile.id
            name: profile.displayName
            familyName: profile.name.familyName
            givenName: profile.name.givenName
            email: profile._json.email
            picture: profile._json.picture
            gender: profile._json.gender
          }).save (err, saved) ->
            sockets.emit 'reloadUsers' if saved
            done(err, saved)

  passport.serializeUser (user, done) ->
    done(null, user)

  passport.deserializeUser (obj, done) ->
    done(null, obj)

exports.route = (app, requireGuest) ->

  app.get '/auth/google', requireGuest,
    passport.authenticate('google',
      scope: ['https://www.googleapis.com/auth/userinfo.profile',
              'https://www.googleapis.com/auth/userinfo.email']), ->

  app.get '/auth/google/callback', requireGuest,
    passport.authenticate('google', failureRedirect: '/'), (req, res) ->
      req.session?.user = req.session.passport?.user
      res.redirect '/'
