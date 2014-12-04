@Quizzes = new Mongo.Collection "quizzes"
@LiveGames = new Mongo.Collection "games"

Router.configure layoutTemplate: 'layout'

Router.route '/', ->
    if Meteor.user()
        @redirect "/dash"
    else
        @redirect "/welcome"

Meteor.methods
    host: (options) ->
        if not @userId
            throw new Meteor.Error("logged-out", "The user must be logged in to host a quiz")
        if not _.isObject(Quizzes.findOne(options.quiz))
            throw new Meteor.Error("no-such-quiz", "There's no quiz with the id provided")
        shortid = Math.floor(Math.random() * Math.pow(10, SHORTID_DIGITS))
        while LiveGames.findOne({shortid: shortid})?
            shortid = Math.floor(Math.random() * Math.pow(10, SHORTID_DIGITS))
        overrides = shortid: "#{shortid}", players: [], answers: [[]], owner: @userId
        LiveGames.insert _.extend options, overrides
        return shortid

if Meteor.isClient
    Template.registerHelper "ago", (time) -> moment(time).fromNow()
    Template.registerHelper "dump", -> JSON.stringify(Template.currentData())
    
    Template.navbar.helpers
        link: (path, text) ->
            activeString = if new RegExp(path).test(Router.current().url) then "class='active'" else ""
            Spacebars.SafeString "<li #{activeString}><a href='#{path}'>#{text}</a></li>"
        activeon: (path) ->
            if new RegExp(path).test(Router.current().url)
                "active"

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
                {"text":"Do you know that Kapuut exists?","answers":["No","Yes"],"correctAnswer":1}
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
                    {"text":"Do you know that Kapuut exists?","answers":["No","Yes"],"correctAnswer":1}
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
