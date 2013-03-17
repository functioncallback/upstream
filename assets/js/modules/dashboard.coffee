App.Controller.Dashboard = ['$scope', '$rootScope', 'User', (scope, rootScope, User) ->
  rootScope.title = 'Dashboard'
  rootScope.object = undefined
  scope.users = User.query()
]
