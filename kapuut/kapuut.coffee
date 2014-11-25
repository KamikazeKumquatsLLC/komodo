@Quizzes = new Mongo.Collection "quizzes"
@LiveGames = new Mongo.Collection "games"

Router.configure layoutTemplate: 'layout'

Router.route '/', ->
    if Meteor.user()
        @redirect "/dash"
    else
        @redirect "/welcome"

Router.route "/welcome", ->
    @render "welcome"

Router.route '/dash', ->
    #if Meteor.user()
        @render "dashboard"
    #else
    #    @redirect "/welcome"

Router.route "/view/:id", ->
    #if not Meteor.user()
    #    @redirect "/welcome"
    #else
        @render "view", data: -> Quizzes.findOne @params.id

Router.route "/host/:id", ->
    @render "host", data: -> Quizzes.findOne @params.id

Router.route "/play/:shortid", ->
    @layout ""
    @render "play", data: -> LiveGames.findOne shortid: @params.shortid

if Meteor.isClient
    # counter starts at 0
    Session.setDefault "counter", 0
    
    Template.registerHelper "ago", (time) -> moment(time).fromNow()
    Template.registerHelper "dump", -> JSON.stringify(Template.currentData())
    
    Template.navbar.helpers
        link: (path, text) ->
            activeString = if new RegExp(path).test(Router.current().url) then "class='active'" else ""
            Spacebars.SafeString "<li #{activeString}><a href='#{path}'>#{text}</a></li>"
        activeon: (path) ->
            if new RegExp(path).test(Router.current().url)
                "active"
    
    Template.dashboard.helpers
        quizzes: -> Quizzes.find {}
    
    Template.welcome.events
        'click #getstarted': ->
            $("#login-sign-in-link").one "click", -> Meteor.setTimeout((-> $("#signup-link").click()), 0)
            $("#login-sign-in-link").click()
    
    Template.view.helpers
        correctIndicator: ->
            correct = Template.parentData(1).correctAnswer is Template.parentData(1).answers.indexOf(Template.currentData())
            if correct
                "plus"
            else
                "minus"
    
    Meteor.startup ->
        Session.setDefault "loginSeen", Meteor.user()?
        
        Tracker.autorun (c) ->
            if Meteor.status().connected and Meteor.user() and Session.equals("loginSeen", no) and location.pathname is "/welcome"
                powerLog "Helpfully bouncing just-logged-in user to dashboard"
                location.href = "/dash"
                Session.set "loginSeen", yes
            if Meteor.status().connected and not Meteor.user()
                Session.set "loginSeen", no

if Meteor.isServer
    Meteor.startup ->
        # do something
