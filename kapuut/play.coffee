Router.route "/play/:shortid", ->
    @wait Meteor.subscribe "quizPlay", @params.shortid
    
    if @ready()
        console.log @params.shortid
        console.log LiveGames.findOne(shortid: @params.shortid)
        @layout ""
        @render "play", data: -> LiveGames.findOne shortid: @params.shortid
    else
        @render "loading"

if Meteor.isClient
    Template.play.helpers
        name: ->
            if Template.currentData().name?
                Template.currentData().name
            else
                Quizzes.findOne(Template.currentData().quiz).name
    
    Template.play.events
        'click #begin': (evt) ->
            # this is complicated
            shortid = Math.floor(Math.random() * 1000000)
            while LiveGames.findOne({shortid: shortid})?
                shortid = Math.floor(Math.random() * 1000000)
            id = Router.current().params.id
            LiveGames.insert {quiz: id, shortid: shortid}
            Router.go "/play/#{shortid}"
            # don't follow the link
            return no
