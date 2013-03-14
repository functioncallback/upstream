class App.Model.Stream

App.Controller.Streams = ['$scope', '$rootScope', '$location', 'Stream',
  (scope, rootScope, location, Stream) ->

    scope.streams = Stream.query()

    App.socket.on 'reload:streams', ->
      apply 'streams', Stream.query()
      scope.cancel()

    App.socket.on 'err', (err) ->
      setTimeout((-> apply 'err', undefined, rootScope), 3000)
      apply 'err', err, rootScope

    scope.open = ->
      location.url "/#{@s.slug}"

    scope.new = ->
      scope.stream = new Stream()

    scope.edit = ->
      scope.stream = new Stream(@s)

    scope.isNew = ->
      scope.stream and not scope.stream._id

    scope.editable = ->
      return unless scope.stream
      scope.stream._id == @s?._id

    scope.cancel = (delay = 0) ->
      setTimeout((-> scope.$apply -> scope.stream = null), delay)

    scope.create = ->
      App.socket.emit('post:stream', scope.stream) unless scope.stream?._id

    scope.update = ->
      App.socket.emit('put:stream', scope.stream) if scope.stream?._id

    scope.delete = ->
      App.socket.emit('delete:stream', scope.stream._id) if scope.stream?._id

    apply = (key, value, target = scope) ->
      target.$apply -> target[key] = value
]
