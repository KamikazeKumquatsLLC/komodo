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
    
    Template.navbar.helpers
        link: (path, text) ->
            activeString = if new RegExp(path).test(Router.current().url) then "class='active'" else ""
            Spacebars.SafeString "<li #{activeString}><a href='#{path}'>#{text}</a></li>"
        activeon: (path) ->
            if new RegExp(path).test(Router.current().url)
                "active"

if Meteor.isServer
    Meteor.startup ->
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
    Meteor.publish "allQuizzes", -> Quizzes.find owner: @userId
    Meteor.publish "quiz", (id) -> Quizzes.find id
    Meteor.publish "gameIDs", -> LiveGames.find({}, {fields: shortid: 1})
    Meteor.publish "quizPlay", (shortid) ->
        check(shortid, String)
        game = LiveGames.findOne({shortid: shortid})
        quizId = game.quiz
        return [Quizzes.find(quizId), LiveGames.find({shortid: shortid})]
