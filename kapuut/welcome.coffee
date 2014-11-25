Router.route "/welcome", ->
    @render "welcome"

if Meteor.isClient
    Template.welcome.events
        'click #getstarted': ->
            $("#login-sign-in-link").one "click", -> Meteor.setTimeout((-> $("#signup-link").click()), 0)
            $("#login-sign-in-link").click()

    Meteor.startup ->
        Session.setDefault "loginSeen", Meteor.user()?
        
        Tracker.autorun (c) ->
            if Meteor.status().connected and Meteor.user() and Session.equals("loginSeen", no) and location.pathname is "/welcome"
                powerLog "Helpfully bouncing just-logged-in user to dashboard"
                location.href = "/dash"
                Session.set "loginSeen", yes
            if Meteor.status().connected and not Meteor.user()
                Session.set "loginSeen", no
