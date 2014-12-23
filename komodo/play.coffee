Router.route "/play/:shortid", ->
    @wait Meteor.subscribe "quizPlay", @params.shortid
    
    if @ready()
        @layout ""
        Session.set "gameid", LiveGames.findOne(shortid: @params.shortid)._id
        @render "play", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

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
            LiveGames.update Session.get("gameid"), {$pull: {players: id: Session.get("playerid")}}
            LiveGames.update Session.get("gameid"), {$push: players: {id: Session.get("playerid"), name: $("#playername").val(), score: 0}}
            window.addEventListener "beforeunload", ->
                LiveGames.update Session.get("gameid"), {$pull: {players: id: Session.get("playerid")}}
        'click .oldname': (evt) ->
            $("#playername").val(evt.currentTarget.innerText)
    
    Template.play.events
        'click #reset': (evt) ->
            LiveGames.update Session.get("gameid"), {$pull: {players: id: Session.get("playerid")}}
    
    Template.question.helpers
        timer: -> getGame().timer
    
    Template.question.events
        "click .answer": (evt) ->
            selectedAnswer = evt.currentTarget.dataset.original
            answerList = Template.currentData().answers
            answer = answerList.indexOf(selectedAnswer)
            modifier = $push: {}
            modifier.$push["answers.#{getGame().question}"] = {id: Session.get("playerid"), answer: answer}
            LiveGames.update Session.get("gameid"), modifier
            no
    
    correct = -> _.filter(_.zip(_(getQuiz().questions).pluck("correctAnswer"), _.map(getGame().answers, (list) -> _.findWhere(list, id: Session.get("playerid"))?.answer)), ([correct, mine]) -> mine? and correct? and correct is mine).length
    total = -> _(getQuiz().questions).chain().pluck("correctAnswer").filter(_.isNumber).value().length
    
    Template.results.helpers
        correct: correct
        total: total
        pct: -> Math.round(10000*correct()/total())/100
        score: -> getMe().score
