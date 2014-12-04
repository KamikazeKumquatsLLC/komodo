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
            countdown = parseInt $("#inputCountdownLength").val()
            if countdown < 0 or countdown isnt parseInt "#{countdown}"
                console.log "Stuff broke!"
                countdown = 5
            options =
                quiz: id
                name: name
                countdownlength: countdown
            Meteor.call "host", options, (err, shortid) ->
                unless err
                    Router.go "/host/#{shortid}"
            return no
