Router.route "/host/:shortid", ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @layout ""
        Session.set "shortid", @params.shortid
        @render "host", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

if Meteor.isClient
    makeProxy = (attr) -> ->
        if Template.currentData()[attr]?
            Template.currentData()[attr]
        else
            Quizzes.findOne(Template.currentData().quiz)[attr]
    
    Template.prep.helpers
        playurl: -> Router.current().url.replace("host", "play")
        encplayurl: -> encodeURIComponent Router.current().url.replace("host", "play")
        count: -> Template.currentData().players.length
        name: makeProxy "name"
        description: makeProxy "description"
    
    Template.prep.events
        'click #begin': (evt) ->
            gameid = LiveGames.findOne({shortid: Session.get("shortid")})._id
            LiveGames.update gameid, $set: begun: new Date()
