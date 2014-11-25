Router.route "/play/:shortid", ->
    @wait Meteor.subscribe "quizPlay", @params.shortid
    
    if @ready()
        @layout ""
        Session.set "shortid", @params.shortid
        @render "play", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

if Meteor.isClient
    makeProxy = (attr) -> ->
        if Template.currentData()[attr]?
            Template.currentData()[attr]
        else
            Quizzes.findOne(Template.currentData().quiz)[attr]
    
    Template.registerHelper "playername", ->
        _.filter(LiveGames.findOne(shortid: Session.get("shortid")).players, ({id, name}) -> id is Session.get("playerid"))[0]?.name
    
    Template.play.helpers
        name: makeProxy "name"
    
    Template.play.events
        'click #generate': (evt) ->
            index = Math.floor(Math.random() * SAMPLE_NAMES.length)
            $("#playername").val(SAMPLE_NAMES[index])
        'click #accept': (evt) ->
            Session.setDefault("playerid", Math.random())
            gameid = LiveGames.findOne({shortid: Session.get("shortid")})._id
            LiveGames.update gameid, {$pull: {players: id: Session.get("playerid")}}
            LiveGames.update gameid, {$push: players: {id: Session.get("playerid"), name: $("#playername").val()}}
        'click #reset': (evt) ->
            gameid = LiveGames.findOne({shortid: Session.get("shortid")})._id
            LiveGames.update gameid, {$pull: {players: id: Session.get("playerid")}}
