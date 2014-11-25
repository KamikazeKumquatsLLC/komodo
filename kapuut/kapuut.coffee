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
                "lastmod":"2014-11-24T20:41:57.425Z"
                "name":"hi"
                "questions": [
                    {"text":"Do you even?","answers":["No","Yes"],"correctAnswer":1}
                    {"text":"Are you sure?","answers":["No","Yes"]}
                    {"text":"That's interesting."}
                ]
    Meteor.publish "everything", -> [Quizzes.find({}), LiveGames.find({})]
    Meteor.publish "quizPlay", (shortid) ->
        check(shortid, String)
        console.log "Getting quiz for game ##{shortid}"
        game = LiveGames.findOne()# {shortid: shortid})
        console.log "Found game #{game}"
        quizId = game.quiz
        return [Quizzes.find(quizId), LiveGames.find({shortid: shortid})]
