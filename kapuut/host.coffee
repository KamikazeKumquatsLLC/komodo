Router.route "/host/:shortid", ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @layout ""
        @render "host", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

if Meteor.isClient
    Template.host.helpers
        playurl: -> Router.current().url.replace("host", "play")
        encplayurl: -> encodeURIComponent Router.current().url.replace("host", "play")
    
    Template.host.events
        'click #begin': (evt) ->
            # this is complicated
            shortid = Math.floor(Math.random() * 1000000)
            while LiveGames.findOne({shortid: shortid})?
                shortid = Math.floor(Math.random() * 1000000)
            id = Router.current().params.id
            LiveGames.insert {quiz: id, shortid: shortid}
            Router.go "/host/#{shortid}"
            # don't follow the link
            return no
