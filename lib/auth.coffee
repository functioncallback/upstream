fs = require 'fs'
path = require 'path'
passport = require 'passport'
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
_ = require 'underscore'

exports.init = (sockets) ->

  passport.use new GoogleStrategy config.auth.google, (accessToken, refreshToken, profile, done) ->
    process.nextTick () ->
      console.log 'authenticating', profile
      User.findOne { auth: googleId: profile.id }, (err, existing) ->
        console.log err, existing
        return done(err) if err

        if existing
          changes = _.pick(existing, 'name', 'familyName', 'givenName', 'email', 'picture', 'gender')
          console.log 'updating user', changes
          User.update { _id: existing._id }, { $set: changes }, (err) ->
            console.log 'err', err
            return done err if err
            sockets.emit 'reload:users'
            User.findOne { _id: existing._id }, (err, user) =>
              console.log err, user
              done(null, user)

        else
          console.log 'creating user', profile
          new User({
            auth: googleId: profile.id
            name: profile.displayName
            familyName: profile.name.familyName
            givenName: profile.name.givenName
            email: profile._json.email
            picture: profile._json.picture
            gender: profile._json.gender
          }).save (err, saved) ->
            console.log err, saved
            sockets.emit 'reload:users' if saved
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
