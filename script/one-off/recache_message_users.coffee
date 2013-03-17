  Message.find {}, {from:1,fromId:1}, (err, messages) ->
    return console.log 'err finding messages', err if err
    _.each messages, (m) ->
      return if m.from.picture
      User.findOne { _id: m.fromId }, (err, user) ->
        return console.log 'err finding user', err if err
        return console.log 'user not found with fromId', m.fromId if not user
        f = _.pick(user, 'name', 'picture', 'updatedAt')
        Message.update { _id: m._id }, { $set: { from: f } }, (err) ->
          console.log 'err updating message', err if err
