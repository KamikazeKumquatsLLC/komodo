Router.route "/host/:shortid", ->
    @wait Meteor.subscribe "quizHost", @params.shortid
    
    if @ready()
        @layout ""
        Session.set "shortid", @params.shortid
        @render "host", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

countdowns = {}
timers = {}

Meteor.methods
    startCountdown: (gameid) ->
        unless @isSimulation
            unless countdowns[gameid]
                game = LiveGames.findOne(gameid)
                LiveGames.update gameid, $set: {revealed: no, countdown: game.countdownlength}
                update = ->
                    LiveGames.update gameid, $inc: countdown: -1
                    if LiveGames.findOne(gameid).countdown <= 0
                        Meteor.call "stopCountdown", gameid
                countdowns[gameid] = Meteor.setInterval update, 1000
        no
    stopCountdown: (gameid) ->
        if countdowns[gameid]
            Meteor.clearInterval countdowns[gameid]
            countdowns[gameid] = undefined
            LiveGames.update gameid, {$inc: {question: 1}, $push: {answers: []}}
            Meteor.call "startTimer", gameid
        no
    startTimer: (gameid) ->
        unless @isSimulation
            unless timers[gameid]
                {quiz, question} = LiveGames.findOne(gameid)
                quiz = Quizzes.findOne(quiz)
                if quiz.questions[question].time
                    LiveGames.update gameid, $set: timer: quiz.questions[question].time
                    update = ->
                        LiveGames.update gameid, $inc: timer: -1
                        if LiveGames.findOne(gameid).timer <= 0
                            Meteor.call "stopTimer", gameid
                    timers[gameid] = Meteor.setInterval update, 1000
        no
    stopTimer: (gameid) ->
        if timers[gameid]
            Meteor.clearInterval timers[gameid]
            LiveGames.update gameid, $set: timer: 0, revealed: yes
            timers[gameid] = undefined
        no

if Meteor.isClient
    getGame = -> LiveGames.findOne shortid: Session.get "shortid"
    getQuiz = -> Quizzes.findOne getGame().quiz
    getQuestion = -> getQuiz().questions[getGame().question]
    
    makeProxy = (attr) -> ->
        if getGame()[attr]?
            getGame()[attr]
        else
            getQuiz()[attr]
    
    Template.host.helpers
        currentQuestion: -> getQuestion()
    
    Template.prep.rendered = ->
        Tracker.autorun (comp) ->
            if getGame().players.length is getGame().expected
                comp.stop()
                $("#begin").click()
    
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
        gamename: makeProxy "name"
        description: makeProxy "description"
    
    Template.hostquestion.helpers
        numAnswers: -> getGame().answers[getGame().question].length
        numPlayers: -> getGame().players.length
        count: ->
            index = getQuestion().answers.indexOf(Template.currentData())
            _.filter(getGame().answers[getGame().question], ({answer}) -> answer is index).length
        color: ->
            index = getQuestion().answers.indexOf(Template.currentData())
            if _.isNumber getQuestion().correctAnswer
                if getQuestion().correctAnswer is index
                    "success"
                else
                    "danger"
            else
                "info"
        guessers: ->
            index = getQuestion().answers.indexOf(Template.currentData())
            tmp = _.chain(getGame().answers[getGame().question])
            tmp = tmp.where(answer: index)
            tmp = tmp.map(({id}) -> _.findWhere(getGame().players, id: id))
            tmp = tmp.compact() # remove falsy values
            tmp = tmp.pluck("name")
            tmp.value()
        answerable: -> getQuestion().answers?
        last: -> getQuiz().questions.length - 1 is getGame().question
        top5players: ->
            _(getGame().players).chain()
                .sortBy(({score}) -> -score)
                .first(5)
                .value()
        timer: -> getGame().timer
    
    Template.prep.events
        'click #begin': (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: {question: -1, begun: yes, answers: [[]]}
            Meteor.call "startCountdown", gameid
    
    Template.hostquestion.events
        "click #reveal": (evt) ->
            gameid = getGame()._id
            Meteor.call "stopTimer", gameid
            LiveGames.update gameid, $set: revealed: yes
        "click #advance": (evt) ->
            gameid = getGame()._id
            Meteor.call "startCountdown", gameid
        "click #end": (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: over: yes
    
    Template.hoststats.helpers
        top5players: ->
            _(getGame().players).chain()
                .sortBy(({score}) -> -score)
                .first(5)
                .value()
    
    Template.hoststats.events
        "click #exit": (evt) ->
            Router.go "/dash"
            LiveGames.remove(getGame()._id)
        "click #restart": (evt) ->
            LiveGames.update getGame()._id, $set:
                answers: [[]]
                begun: no
                over: no
                question: 0
                revealed: no
            no
