@Quizzes = new Mongo.Collection "quizzes"

Iron.Router.hooks.landWithoutAuth = ->
    if not Meteor.user()
        @render "landing"
    else
        @next()

Router.route '/', ->
    if Meteor.user()
        @render "dashboard"
    else
        @render "landing"

Router.route "/view/:id", ->
    @render "view", data: -> Quizzes.findOne @params.id
, name: "view"

Router.onBeforeAction "landWithoutAuth", only: ["view"]

if Meteor.isClient
    # counter starts at 0
    Session.setDefault "counter", 0

    Template.registerHelper "ago", (time) -> moment(time).fromNow()
    Template.registerHelper "dump", -> JSON.stringify(Template.currentData())

    Template.navbar.helpers
        rootname: -> if Meteor.user() then "Dashboard" else "Home"

    Template.dashboard.helpers
        quizzes: -> Quizzes.find {}

    Template.landing.events
        'click #getstarted': ->
            $("#login-sign-in-link").one "click", -> Meteor.setTimeout((-> $("#signup-link").click()), 0)
            $("#login-sign-in-link").click()

if Meteor.isServer
    Meteor.startup ->
        # do something
