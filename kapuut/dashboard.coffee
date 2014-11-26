Router.route '/dash', ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @render "dashboard"
    else
        @render "loading"

if Meteor.isClient
    Template.dashboard.helpers
        quizzes: -> Quizzes.find {}
    
    Template.dashboard.events
        "click #new": (evt) ->
            id = Quizzes.insert({name: "New Quiz",lastmod: new Date()})
            Router.go "/edit/#{id}"
