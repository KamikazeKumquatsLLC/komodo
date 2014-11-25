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
    
    makeProxy = (attr) -> ->
        if Template.currentData()[attr]?
            Template.currentData()[attr]
        else
            Quizzes.findOne(Template.currentData().quiz)[attr]
    
    Template.registerHelper "playername", ->
        _.filter(getGame().players, ({id, name}) -> id is Session.get("playerid"))[0]?.name
    
    Template.play.helpers
        currentQuestion: -> getQuiz().questions[getGame().question]
        answered: ->
            list = getGame().answers[getGame().question]
            criterion = ({id}) -> Session.equals("playerid", id)
            filtered = _.filter(list, criterion)
            filtered[0]?
    
    Template.enterplayername.helpers
        name: makeProxy "name"
    
    Template.play.events
        'click #generate': (evt) ->
            index = Math.floor(Math.random() * SAMPLE_NAMES.length)
            $("#playername").val(SAMPLE_NAMES[index])
        'click #accept': (evt) ->
            Session.setDefault("playerid", Math.random())
            LiveGames.update Session.get("gameid"), {$pull: {players: id: Session.get("playerid")}}
            LiveGames.update Session.get("gameid"), {$push: players: {id: Session.get("playerid"), name: $("#playername").val()}}
            window.addEventListener "beforeunload", ->
                LiveGames.update Session.get("gameid"), {$pull: {players: id: Session.get("playerid")}}
        'click #reset': (evt) ->
            LiveGames.update Session.get("gameid"), {$pull: {players: id: Session.get("playerid")}}
    
    Template.question.events
        "click .answer": (evt) ->
            selectedAnswer = evt.currentTarget.innerText
            answerList = Template.currentData().answers
            answer = answerList.indexOf(selectedAnswer)
            console.log "Answering #{answer}"
            LiveGames.update Session.get("gameid"), {$push: "answers.0": {id: Session.get("playerid"), answer: answer}}
            no
