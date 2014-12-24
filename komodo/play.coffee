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
    answer: ({playerid, gameid, question, answer}) ->
        modifier = $push: {}, $inc: {}
        modifier.$push["answers.#{question}"] = {id: playerid, answer: answer}
        {timer, players, quiz, question} = LiveGames.findOne(gameid)
        quiz = Quizzes.findOne(quiz)
        question = quiz.questions[question]
        if _.isNumber(question.correctAnswer)
            if question.correctAnswer is answer
                i = (i for val, i in players when val.id is playerid)[0]
                value = if _.isNumber(question.value) then question.value else 1000
                timeScale = 1
                if _.isNumber(question.time)
                    timeScale = question.time - timer + 1
                modifier.$inc["players.#{i}.score"] = value / timeScale
        LiveGames.update gameid, modifier

if Meteor.isClient
    getGame = -> LiveGames.findOne Session.get "gameid"
    getQuiz = -> Quizzes.findOne getGame().quiz
    getMe = -> _.findWhere getGame().players, id: Session.get("playerid")
    
    makeProxy = (attr) -> ->
        if Template.currentData()[attr]?
            Template.currentData()[attr]
        else
            Quizzes.findOne(Template.currentData().quiz)[attr]
    
    Template.registerHelper "playername", ->
        getMe()?.name
    
    Template.play.helpers
        currentQuestion: -> getQuiz().questions[getGame().question]
        answered: ->
            list = getGame().answers[getGame().question]
            criterion = ({id}) -> Session.equals("playerid", id)
            filtered = _.filter(list, criterion)
            filtered[0]?
    
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
            Meteor.call "removePlayer",
                gameid: Session.get("gameid")
                playerid: Session.get("playerid")
            Meteor.call "addPlayer",
                gameid: Session.get("gameid")
                playerid: Session.get("playerid")
                name: $("#playername").val()
            window.addEventListener "beforeunload", ->
                Meteor.call "removePlayer",
                    gameid: Session.get("gameid")
                    playerid: Session.get("playerid")
        'click .oldname': (evt) ->
            $("#playername").val(evt.currentTarget.innerText)
    
    Template.play.events
        'click #reset': (evt) ->
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
                question: getGame().question
                gameid: Session.get("gameid")
                answer: answer
            no
    
    correct = -> _.filter(_.zip(_(getQuiz().questions).pluck("correctAnswer"), _.map(getGame().answers, (list) -> _.findWhere(list, id: Session.get("playerid"))?.answer)), ([correct, mine]) -> mine? and correct? and correct is mine).length
    total = -> _(getQuiz().questions).chain().pluck("correctAnswer").filter(_.isNumber).value().length
    
    Template.results.helpers
        correct: correct
        total: total
        pct: -> Math.round(10000*correct()/total())/100
        score: -> getMe().score
