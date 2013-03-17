# namespace
window.App = Model: {}, Controller: {}

# socket.io
App.socket = io.connect()

# ng-app

module = angular.module('upstream', ['api', 'ui']).config ['$routeProvider', '$locationProvider',
  (routeProvider, locationProvider) ->
    locationProvider.html5Mode(true)

    routeProvider
      .when('/', controller: App.Controller.Dashboard, templateUrl: '/partials/dashboard')
      .when('/:slug', controller: App.Controller.Messages, templateUrl: '/partials/messages')
      .when('/user/:id', controller: App.Controller.PrivateMessages, templateUrl: '/partials/messages')
      .when('/message/:id', controller: App.Controller.Message, templateUrl: '/partials/messages')
      .when('/private/:id', controller: App.Controller.PrivateMessage, templateUrl: '/partials/messages')
      .otherwise(redirectTo: '/')
]

# api

endpoint = (pluralized) -> "/v1/#{pluralized}/:id"

lab = angular.module('api', ['ngResource'])
lab.factory 'User', ['$resource', (resource) -> build(resource, 'User', 'users')]
lab.factory 'Stream', ['$resource', (resource) -> build(resource, 'Stream', 'streams')]
lab.factory 'Message', ['$resource', (resource) -> build(resource, 'Message', 'messages')]
lab.factory 'PrivateMessage', ['$resource', (resource) -> build(resource, 'PrivateMessage', 'private-messages')]

build = (resource, name, pluralized) ->
  Resource = resource endpoint(pluralized), update: method: 'PUT'
  angular.extend(Resource, App.Model[name]?.prototype)
  Resource

# directives

module.directive 'socket', () ->
  return (scope, element, attributes) ->
    connected = $('#connected')
    disconnected = $('#disconnected')
    App.socket.on 'disconnect', ->
      connected.css(opacity: .3, 'pointer-events': 'none')
      disconnected.show()

module.directive 'autoscroll', () ->
  return (scope, element, attrs) ->
    return unless scope.$first
    $('#messages').scrollTop 0

module.directive 'bypass', () ->
  return (scope, element, attrs) ->
    $(element).click (event) ->
      event.stopImmediatePropagation()
      event.stopPropagation()
      event.preventDefault()
