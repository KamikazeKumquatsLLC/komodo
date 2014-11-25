Router.route "/prehost/:id", ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @render "prehost", data: -> Quizzes.findOne @params.id
    else
        @render "loading"

if Meteor.isClient
    Template.prehost.events
        'click #begin': (evt) ->
            shortid = Math.floor(Math.random() * Math.pow(10, SHORTID_DIGITS))
            while LiveGames.findOne({shortid: shortid})?
                shortid = Math.floor(Math.random() * Math.pow(10, SHORTID_DIGITS))
            id = Router.current().params.id
            # make sure it goes in as a string to prevent massive headaches
            LiveGames.insert {quiz: id, shortid: "#{shortid}", players: []}
            Router.go "/host/#{shortid}"
            # don't follow the link
            return no
