class App.Model.Message
class App.Model.PrivateMessage

init = (object, $rootScope) ->
  $rootScope.title = object.name
  $rootScope.object = object
  App.namespace?.disconnect?()
  App.namespace = undefined

class App.Controller.Messages
  constructor: ($scope, $rootScope, $routeParams, $location, Stream, Message) ->
    Stream.query { slug: $routeParams.slug }, (streams) ->
      stream = _.first(streams)
      return $location.url('/') unless stream

      init stream, $rootScope, $location
      App.namespace = io.connect("/stream/#{stream._id}")

      App.socket.on 'put:stream', (updated) ->
        $location.url("/#{updated.slug}") if stream._id = updated._id and stream.slug != updated.slug

      App.socket.on 'delete:stream', (id) ->
        $location.url("/") if stream._id = id

      App.namespace.on 'post:message', (message) ->
        $scope.$apply -> $scope.messages.push message

      Message.query { toId: stream._id }, (messages) ->
        $scope.messages = messages

class App.Controller.PrivateMessages
  constructor: ($scope, $rootScope, $routeParams, $location, User, PrivateMessage) ->
    User.get { id: $routeParams.id }, (user) ->
      return $location.url('/') unless user
      init user, $rootScope, $location

      App.socket.on 'post:private', (message) ->
        $scope.$apply -> $scope.messages.push message

      PrivateMessage.query { fromOrTo: user._id }, (messages) ->
        $scope.messages = messages

class App.Controller.Footer
  constructor: ($scope, $rootScope, Message) ->
    $scope.send = ($event) ->
      $event.preventDefault()
      message = _.extend($scope.message, toId: $rootScope.object._id)
      $scope.message = null
      if message.body?.length
        App.namespace.emit('post:message', message) if App.namespace
        App.socket.emit('post:private', message) unless App.namespace
