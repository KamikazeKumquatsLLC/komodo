@Quizzes = new Mongo.Collection "quizzes"
@LiveGames = new Mongo.Collection "games"

Router.configure layoutTemplate: 'layout'

Router.route '/', ->
    if Meteor.user()
        @redirect "/dash"
    else
        @redirect "/welcome"

if Meteor.isClient
    Template.registerHelper "ago", (time) -> moment(time).fromNow()
    Template.registerHelper "dump", -> JSON.stringify(Template.currentData())
    Template.registerHelper "didyouknow", ->
        Session.set("didyouknow", _.random(DID_YOU_KNOW.length)) until Session.get("didyouknow")
        DID_YOU_KNOW[Session.get("didyouknow")]
    Template.registerHelper "scales", (num) ->
        if num is 1
            "1 scale"
        else
            "#{num} scales"
    
    Template.navbar.helpers
        link: (path, text) ->
            activeString = if new RegExp(path).test(Router.current().url) then "class='active'" else ""
            Spacebars.SafeString "<li #{activeString}><a href='#{path}'>#{text}</a></li>"
        activeon: (path) ->
            if new RegExp(path).test(Router.current().url)
                "active"
    
    Template.loading.rendered = ->
        row = (n) -> ->
            $.Velocity.animate
                elements: document.querySelectorAll(".row#{n}")
                properties:
                    scaleY: "+=2"
                    translateY: "-=52"
                    opacity: 1
        tri = (n) -> ->
            $.Velocity.animate
                elements: document.querySelectorAll(".row1 :nth-child(#{n})")
                properties:
                    scale: "+=2"
                    translateX: "-=15"
                    translateY: "-=26"
                    opacity: 1
        
        run = ->
            $("*[data-initial-properties]").each ->
                $(@).velocity
                    properties: JSON.parse @dataset.initialProperties
                    options:
                        duration: 0
            
            $.Velocity.animate
                elements: document.querySelectorAll ".row1 :first-child"
                properties:
                    opacity: 1
            .then tri 2
            .then tri 3
            .then tri 4
            .then tri 5
            .then row 2
            .then row 3
            .then row 4
            .then -> $.Velocity.animate
                elements: document.querySelectorAll("svg")
                properties: opacity: 0
                options: delay: 500
            .then run
        run()

if Meteor.isServer
    Quizzes.allow
        insert: (userId, doc) -> userId and doc.owner is userId
        update: (userId, doc, fields, modifier) -> doc.owner is userId
        remove: (userId, doc) -> doc.owner is userId
        fetch: ["owner"]
    
    Quizzes.deny
        update: (userId, doc, fields, modifier) -> _.contains fields, "owner"
        fetch: []
    
    LiveGames.allow
        update: (userId, doc, fields, modifier) -> (userId is doc.owner) or _.without(fields, "players", "answers").length is 0
        remove: (userId, doc) -> userId is doc.owner
        fetch: []
    
    LiveGames.deny
        update: (userId, doc, fields, modifier) -> _.contains fields, "quiz" or _.contains fields, "owner"
        fetch: []
    
    Accounts.onCreateUser (options, user) ->
        Quizzes.insert
            "description":"A sample quiz of awesomeness."
            "lastmod":new Date()
            "name":"Sample Quiz"
            owner: user._id
            "questions": [
                {"text":"Do you know that Komodo exists?","answers":["No","Yes"],"correctAnswer":1}
                {"text":"Do you know how it works?","answers":["No","Yes"]}
                {"text":"There's always more to learn."}
            ]
        return user
    Meteor.startup ->
        ###
        if Quizzes.find({}).count() is 0
            Quizzes.insert
                "description":"A sample quiz of awesomeness."
                "lastmod":new Date()
                "name":"hi"
                "questions": [
                    {"text":"Do you know that Komodo exists?","answers":["No","Yes"],"correctAnswer":1}
                    {"text":"Do you know how it works?","answers":["No","Yes"]}
                    {"text":"There's always more to learn."}
                ]
        ###
    Meteor.publish "allQuizzes", -> Quizzes.find owner: @userId
    Meteor.publish "quiz", (id) -> Quizzes.find id
    Meteor.publish "gameIDs", -> LiveGames.find({}, {fields: shortid: 1})
    Meteor.publish "quizPlay", (shortid) ->
        check(shortid, String)
        game = LiveGames.findOne({shortid: shortid})
        quizId = game.quiz
        return [Quizzes.find(quizId), LiveGames.find({shortid: shortid})]
