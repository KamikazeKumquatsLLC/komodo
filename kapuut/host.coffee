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
        gamename: makeProxy "name"
        description: makeProxy "description"
    
    Template.hostquestion.helpers
        numAnswers: -> getGame().answers[getGame().question].length
        numPlayers: -> getGame().players.length
        count: ->
            index = getQuiz().questions[getGame().question].answers.indexOf(Template.currentData())
            _.filter(getGame().answers[getGame().question], ({answer}) -> answer is index).length
        color: ->
            index = getQuiz().questions[getGame().question].answers.indexOf(Template.currentData())
            if getQuiz().questions[getGame().question].correctAnswer is index
                "success"
            else
                "danger"
        guessers: ->
            index = getQuiz().questions[getGame().question].answers.indexOf(Template.currentData())
            tmp = _.chain(getGame().answers[getGame().question])
            tmp = tmp.where(answer: index)
            tmp = tmp.map(({id}) -> _.findWhere(getGame().players, id: id))
            tmp = tmp.compact() # remove falsy values
            tmp = tmp.pluck("name")
            tmp.value()
        answerable: -> getQuiz().questions[getGame().question].answers?
        last: -> getQuiz().questions.length - 1 is getGame().question
    
    Template.prep.events
        'click #begin': (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: {begun: yes, countdown: 5, answers: []}
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
        "click #advance": (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: {revealed: no, countdown: 5}
            updateInterval = 0
            update = ->
                LiveGames.update gameid, $inc: countdown: -1
                if getGame().countdown <= 0
                    Meteor.clearInterval updateInterval
                    LiveGames.update gameid, {$inc: {question: 1}, $push: answers: []}
            updateInterval = Meteor.setInterval update, 1000
        "click #end": (evt) ->
            gameid = getGame()._id
            LiveGames.update gameid, $set: over: yes
    
    Template.hoststats.helpers
        top5players: ->
            correctAnswers = _(getQuiz().questions).pluck "correctAnswer"
            total = _.compact(correctAnswers).length
            _(getGame().players).chain()
                .map(({name, id}) -> name: name, answers: _.map getGame().answers, (list) -> _.findWhere list, id: id)
                .map(({name, answers}) -> name: name, answers: _.zip(correctAnswers, _.map(answers, (x) -> x?.answer)))
                .map(({name, answers}) -> name: name, correct: _.filter(answers, ([correct, mine]) -> mine? and correct? and correct is mine).length)
                .map(({name, correct}) -> name: name, pct: Math.round(10000*correct/total)/100)
                .sortBy(({name, pct}) -> -pct)
                .first(5)
                .value()
    
    Template.hoststats.events
        "click #exit": (evt) ->
            LiveGames.remove(getGame()._id)
