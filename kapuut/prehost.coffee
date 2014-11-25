Router.route "/prehost/:id", ->
    @render "prehost", data: -> Quizzes.findOne @params.id

if Meteor.isClient
    Template.prehost.events
        'click #begin': (evt) ->
            # this is complicated
            shortid = Math.floor(Math.random() * 1000000)
            while LiveGames.findOne({shortid: shortid})?
                shortid = Math.floor(Math.random() * 1000000)
            id = Router.current().params.id
            LiveGames.insert {quiz: id, shortid: shortid}
            location.href = "/host/#{shortid}"
            # don't follow the link
            return no
