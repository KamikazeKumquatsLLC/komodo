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
                LiveGames.update gameid,
                    $set: {revealed: no, countdown: game.countdownlength}
                    $inc: question: 1
                    $push: answers: []
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
            game = LiveGames.findOne(gameid)
            {quiz, question} = game
            questionData = Quizzes.findOne(quiz).questions[question]
            set = {}
            set["questionData.#{question}"] = _.omit questionData, "correctAnswer"
            LiveGames.update gameid, $set: set
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
    getGame = -> LiveGames.findOne({shortid: Session.get "shortid"}, options)
    getGameFields = (desired) ->
        desired = [desired] unless _.isArray(desired)
        fields = {}
        for x in desired
            fields[x] = 1
        LiveGames.findOne({shortid: Session.get "shortid"}, {fields: fields})
    getGameField = (desired) -> getGameFields(desired)[desired]
    getQuiz = -> Quizzes.findOne getGameField("quiz")
    getQuestion = -> getQuiz().questions[getGameField("question")]
    getAnswers = -> getGameField("answers")[getGameField("question")]
    
    makeProxy = (attr) -> ->
        if getGameField(attr)?
            getGameField(attr)
        else
            getQuiz()[attr]
    
    Template.host.helpers
        currentQuestion: -> getQuestion()
    
    Template.prep.rendered = ->
        Tracker.autorun (comp) ->
            {players, expected} = getGameFields ["players", "expected"]
            if players.length is expected
                comp.stop()
                $("#begin").click()
    
    Meteor.startup ->
        Tracker.autorun (comp) ->
            game = getGameFields ["revealed", "question", "questionData", "players"]
            return unless game?
            {revealed, question, questionData, players} = game
            if revealed
                modifier = $inc: {}, $set: {}
                _(players).chain()
                          .filter(({tmpscore}) -> tmpscore > 0)
                          .each ({tmpscore}, i) ->
                              modifier.$inc["players.#{i}.score"] = tmpscore
                              modifier.$set["players.#{i}.tmpscore"] = 0
                LiveGames.update game._id, modifier
                unless _.isNumber questionData[question].correctAnswer
                    if _.isNumber getQuestion().correctAnswer
                        set = {}
                        set["questionData.#{question}.correctAnswer"] = getQuestion().correctAnswer
                        LiveGames.update game._id, $set: set
    
    Template.prep.helpers
        playurl: ->
            here = Router.current().url
            if here.indexOf("http") is -1
                here = location.origin + here
            here.replace(/\/host/, "/play")
        encplayurl: ->
            here = Router.current().url
            if here.indexOf("http") is -1
                here = location.origin + here
            encodeURIComponent here.replace(/\/host/, "/play")
        gamename: makeProxy "name"
        description: makeProxy "description"
    
    Template.playerlist.helpers
        count: -> getGameField("players").length
        editing: -> Session.equals "editing", Template.currentData().id
    
    Template.playerlist.events
        "click .kick": (evt) ->
            playerId = parseFloat evt.currentTarget.parentElement.dataset.id
            LiveGames.update getGameField("_id"), $pull: players: id: playerId
        "click .regen": (evt) ->
            playerId = parseFloat evt.currentTarget.parentElement.dataset.id
            {_id, players} = getGameFields(["players", "_id"])
            index = (i for val, i in players when val.id is playerId)[0]
            modifier = $set: {}
            modifier.$set["players.#{index}.name"] = SAMPLE_NAMES[Math.floor(Math.random() * SAMPLE_NAMES.length)]
            LiveGames.update _id, modifier
        "click .edit": (evt) ->
            Session.set "editing", parseFloat evt.currentTarget.parentElement.dataset.id
        "keyup .name-input": (evt) ->
            if evt.keyCode is 13
                playerId = parseFloat evt.currentTarget.dataset.id
                newName = $(evt.target).val()
                {_id, players} = getGameFields(["players", "_id"])
                index = (i for val, i in players when val.id is playerId)[0]
                modifier = $set: {}
                modifier.$set["players.#{index}.name"] = newName
                LiveGames.update _id, modifier
                Session.set "editing"
    
    Template.hostquestion.helpers
        numAnswers: -> getAnswers().length
        numPlayers: -> getGameField("players").length
        count: ->
            index = getQuestion().answers.indexOf(Template.currentData())
            _.filter(getAnswers(), ({answer}) -> answer is index).length
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
            if getGameField("showGuessers")
                index = getQuestion().answers.indexOf(Template.currentData())
                tmp = _.chain(getAnswers())
                tmp = tmp.where(answer: index)
                tmp = tmp.map(({id}) -> _.findWhere(getGameField("players"), id: id))
                tmp = tmp.compact() # remove falsy values
                tmp = tmp.pluck("name")
                tmp.value()
        answerable: -> getQuestion().answers?
        last: -> getQuiz().questions.length - 1 is getGameField("question")
        top5players: ->
            _(getGameField("players")).chain()
                .sortBy(({score}) -> -score)
                .first(5)
                .value()
        timer: -> getGameField("timer")
    
    Template.prep.events
        'click #begin': (evt) ->
            gameid = getGameField("_id")
            LiveGames.update gameid, $set: {question: -1, begun: yes, answers: [], questionData: []}
            Meteor.call "startCountdown", gameid
    
    Template.hostquestion.rendered = -> _.defer ->
        if getGameField("revealWithAllAnswers")
            Tracker.autorun (comp) ->
                game = getGameFields ["answers", "question", "players", "revealed", "countdown"]
                {answers, question, players, revealed, countdown} = game
                unless players.length is 0
                    unless revealed or countdown or answers.length isnt question + 1
                        if players.length is answers[question]?.length
                            $("#reveal").click()
                            comp.stop()
    
    Template.hostquestion.events
        "click #reveal": (evt) ->
            gameid = getGameField("_id")
            Meteor.call "stopTimer", gameid
            LiveGames.update gameid, $set: revealed: yes
        "click #advance": (evt) ->
            gameid = getGameField("_id")
            Meteor.call "startCountdown", gameid
        "click #end": (evt) ->
            gameid = getGameField("_id")
            LiveGames.update gameid, $set: over: yes
    
    Template.hoststats.helpers
        top5players: ->
            _(getGameField("players")).chain()
                .sortBy(({score}) -> -score)
                .first(5)
                .value()
    
    Template.hoststats.events
        "click #exit": (evt) ->
            Router.go "/dash"
            LiveGames.remove(getGameField("_id"))
        "click #restart": (evt) ->
            LiveGames.update getGameField("_id"), $set:
                answers: []
                questionData: []
                begun: no
                over: no
                question: 0
                revealed: no
            no
