class App.Model.User

App.Controller.Users = ['$scope', '$rootScope', '$location', 'User',
  (scope, rootScope, location, User) ->
    scope.users = User.query()

    App.socket.on 'currentUser', (currentUser) ->
      rootScope.$apply -> rootScope.currentUser = currentUser
      App.currentUser = currentUser

    App.socket.on 'reloadUsers', ->
      scope.users = User.query()
      scope.cancel()

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
