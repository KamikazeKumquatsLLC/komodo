@Quizzes = new Mongo.Collection "quizzes"

Router.configure layoutTemplate: 'layout'

doRouting = ->
    Router.route '/', ->
        if Meteor.user()
            powerLog "Dumping authenticated user to dashboard"
            @redirect "/dash"
        else
            powerLog "Dumping unauthenticated user to welcome"
            @redirect "/welcome"

    Router.route "/welcome", ->
        powerLog "Giving user welcome"
        @render "welcome"

    Router.route '/dash', ->
        if Meteor.user()
            powerLog "Giving authenticated user dashboard"
            @render "dashboard"
        else
            powerLog "Dumping unauthenticated user to welcome"
            @redirect "/welcome"

    Router.route "/view/:id", ->
        if not Meteor.user()
            powerLog "Dumping unauthenticated user to welcome"
            @redirect "/welcome"
        else
            powerLog "Giving authenticated user view"
            @render "view", data: -> Quizzes.findOne @params.id
    , name: "view"

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
        doRouting()
        
        Session.setDefault "loginSeen", Meteor.user()?
        
        Tracker.autorun (c) ->
            if Meteor.status().connected and Meteor.user() and Session.equals("loginSeen", no) and location.pathname is "/welcome"
                powerLog "Helpfully bouncing just-logged-in user to dashboard"
                location.href = "/dash"
                Session.set "loginSeen", yes
            if Meteor.status().connected and not Meteor.user()
                Session.set "loginSeen", no

if Meteor.isServer
    doRouting()
    Meteor.startup ->
        # do something
