Router.route "/host/:shortid", ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @layout ""
        Session.set "shortid", @params.shortid
        @render "host", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

if Meteor.isClient
    getGame = -> LiveGames.findOne shortid: Session.get "shortid"
    getQuiz = -> Quizzes.findOne getGame().quiz
    
    makeProxy = (attr) -> ->
        if getGame()[attr]?
            getGame()[attr]
        else
            getQuiz()[attr]
    
    Template.host.helpers
        currentQuestion: -> getQuiz().questions[getGame().question]
    
    Template.prep.helpers
        playurl: ->
            here = Router.current().url
            if here.indexOf("http") is -1
                here = location.origin + here
            here.replace("host", "play")
        encplayurl: ->
            here = Router.current().url
            if here.indexOf("http") is -1
                here = location.origin + here
            encodeURIComponent here.replace("host", "play")
        count: -> getGame().players.length
        name: makeProxy "name"
        description: makeProxy "description"
    
    Template.hostquestion.helpers
        numAnswers: -> getGame().answers[getGame().question].length
        numPlayers: -> getGame().players.length
        count: ->
            index = getQuiz().questions[getGame().question].answers.indexOf(Template.currentData())
            _.filter(getGame().answers[getGame().question], ({answer}) -> answer is index).length
    
    Template.prep.events
        'click #begin': (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: {begun: yes, countdown: 5}
            updateInterval = 0
            update = ->
                LiveGames.update gameid, $inc: countdown: -1
                if getGame().countdown <= 0
                    Meteor.clearInterval updateInterval
                    LiveGames.update gameid, $set: question: 0
            updateInterval = Meteor.setInterval update, 1000
    
    Template.hostquestion.events
        "click #reveal": (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: revealed: yes
