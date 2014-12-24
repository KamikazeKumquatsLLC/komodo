Router.route "/play/:shortid", ->
    @wait Meteor.subscribe "quizPlay", @params.shortid
    
    if @ready()
        @layout ""
        Session.set "gameid", LiveGames.findOne(shortid: @params.shortid)._id
        @render "play", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

Meteor.methods
    addPlayer: ({playerid, gameid, name}) ->
        LiveGames.update gameid, {$push: players: {id: playerid, name: name, score: 0}}
    removePlayer: ({playerid, gameid}) ->
        LiveGames.update gameid, {$pull: {players: id: playerid}}
    getPlayer: ({playerid, gameid}) ->
        _.findWhere LiveGames.findOne(gameid).players, id: playerid
    answer: ({playerid, gameid, answer}) ->
        {revealed, timer, players, quiz, question} = LiveGames.findOne(gameid)
        if revealed
            throw new Error("Tried to answer a question that was already revealed!")
        modifier = $push: {}, $inc: {}
        modifier.$push["answers.#{question}"] = {id: playerid, answer: answer}
        quiz = Quizzes.findOne(quiz)
        question = quiz.questions[question]
        unless @isSimulation
            if _.isNumber(question.correctAnswer)
                if question.correctAnswer is answer
                    i = (i for val, i in players when val.id is playerid)[0]
                    value = if _.isNumber(question.value) then question.value else 1000
                    timeScale = 1
                    if _.isNumber(question.time)
                        timeScale = timer / question.time
                    modifier.$inc["players.#{i}.score"] = Math.floor(value * timeScale)
        LiveGames.update gameid, modifier
    getAnswer: ({playerid, gameid, question}) ->
        list = LiveGames.findOne(gameid).answers[question]
        criterion = ({id}) -> playerid is id
        filtered = _.filter(list, criterion)
        filtered[0]
    getAnswers: ({playerid, gameid}) ->
        list = LiveGames.findOne(gameid).answers
        _.map(list, (list) -> _.findWhere(list, id: playerid)?.answer)

if Meteor.isClient
    getGame = -> LiveGames.findOne Session.get "gameid"
    getQuiz = -> Quizzes.findOne getGame().quiz
    
    makeProxy = (attr) -> ->
        if Template.currentData()[attr]?
            Template.currentData()[attr]
        else
            Quizzes.findOne(Template.currentData().quiz)[attr]
    
    updateScore = ->
        Meteor.call "getPlayer",
            playerid: Session.get("playerid")
            gameid: Session.get("gameid")
        , (error, me) ->
            if error?
                console.log error
            Session.set "playername", me?.name
            Session.set "score", me?.score
    
    Template.registerHelper "playername", -> Session.get("playername")
    
    Template.fancycountdown.rendered = ->
        Session.set "answered", no
    
    Template.play.helpers
        currentQuestion: -> getQuiz().questions[getGame().question]
        answered: -> Session.get "answered"
    
    Template.enterplayername.helpers
        name: makeProxy "name"
        oldnames: -> JSON.parse localStorage.getItem "oldnames"
    
    Template.enterplayername.events
        'click #generate': (evt) ->
            index = Math.floor(Math.random() * SAMPLE_NAMES.length)
            $("#playername").val(SAMPLE_NAMES[index])
        'click #accept': (evt) ->
            localStorage.setItem "oldnames", JSON.stringify _.compact _.union [$("#playername").val()], JSON.parse localStorage.getItem "oldnames"
            Session.setDefault("playerid", Math.random())
            Session.set("playername", $("#playername").val())
            Meteor.call "removePlayer",
                gameid: Session.get("gameid")
                playerid: Session.get("playerid")
            Meteor.apply "addPlayer", [
                gameid: Session.get("gameid")
                playerid: Session.get("playerid")
                name: $("#playername").val()
            ], {wait: yes}
            window.addEventListener "beforeunload", ->
                Meteor.call "removePlayer",
                    gameid: Session.get("gameid")
                    playerid: Session.get("playerid")
        'click .oldname': (evt) ->
            $("#playername").val(evt.currentTarget.innerText)
    
    Template.play.events
        'click #reset': (evt) ->
            Session.set "playername"
            Meteor.call "removePlayer",
                gameid: Session.get("gameid")
                playerid: Session.get("playerid")
    
    Template.question.helpers
        timer: -> getGame().timer
    
    Template.question.events
        "click .answer": (evt) ->
            selectedAnswer = evt.currentTarget.dataset.original
            answerList = Template.currentData().answers
            answer = answerList.indexOf(selectedAnswer)
            Meteor.call "answer",
                playerid: Session.get("playerid")
                gameid: Session.get("gameid")
                answer: answer
            Session.set "answered", yes
            no
    
    updateCorrect = ->
        correctAnswers = _(getQuiz().questions).pluck("correctAnswer")
        Meteor.call "getAnswers",
            playerid: Session.get("playerid")
            gameid: Session.get("gameid")
        , (error, myAnswers) ->
            correctAndMyAnswers = _.zip(correctAnswers, myAnswers)
            wasCorrect = ([correct, mine]) -> mine? and correct? and correct is mine
            correctAnswersIHad = _.filter(correctAndMyAnswers, wasCorrect)
            Session.set "correct", correctAnswersIHad.length
    getTotal = -> _(getQuiz().questions).chain().pluck("correctAnswer").filter(_.isNumber).value().length
    
    Template.results.rendered = ->
        updateCorrect()
        updateScore()
    
    Template.results.helpers
        correct: -> Session.get "correct"
        total: getTotal
        pct: -> Math.round(10000*Session.get("correct")/getTotal())/100
        score: -> Session.get "score"
