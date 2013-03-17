class App.Model.User

App.Controller.Users = ['$scope', '$rootScope', '$location', 'User',
  (scope, rootScope, location, User) ->
    App.socket.on 'current:user', (currentUser) ->
      rootScope.$apply -> rootScope.currentUser = currentUser
      App.currentUser = currentUser

    App.socket.on 'reload:users', ->
      scope.users = User.query()
      scope.cancel()

    App.socket.on 'online', (onlineUserIds) ->
      User.query (users) ->
        scope.users = users.map (u) ->
          u.isOnline = _.include(onlineUserIds, u._id)
          return u

    scope.open = ->
      location.url "/user/#{@u._id}"

    scope.invite = ->
      scope.friend = new User()

    scope.send = ->
      User.invite scope.friend, (friend) ->
        scope.users = User.query()
        scope.cancel()

    scope.cancel = ->
      scope.friend = null
]
