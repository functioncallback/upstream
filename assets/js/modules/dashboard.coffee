App.Controller.Dashboard = ['$scope', '$rootScope', 'User', (scope, rootScope, User) ->
  rootScope.title = 'Dashboard'
  scope.users = User.query()
]
