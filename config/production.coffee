exports.mongo =
  url: process.env.MONGO_URL

exports.auth =
  google:
    clientID: process.env.CLIENT_ID
    clientSecret: process.env.CLIENT_SECRET
    callbackURL: process.env.CALLBACK_URL

exports.io =
  logLevel: 0
  xhr: true
