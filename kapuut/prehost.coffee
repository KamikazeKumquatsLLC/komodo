Router.route "/prehost/:id", ->
    @wait Meteor.subscribe "quiz", @params.id
    @wait Meteor.subscribe "gameIDs"
    
    if @ready()
        @render "prehost", data: -> Quizzes.findOne @params.id
    else
        @render "loading"

if Meteor.isClient
    Template.prehost.events
        'click #begin': (evt) ->
            id = Router.current().params.id
            name = $("#inputName").val()
            Meteor.call "host", {quiz: id, name: name}, (err, shortid) ->
                unless err
                    Router.go "/host/#{shortid}"
            return no
