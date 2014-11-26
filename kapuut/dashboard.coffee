Router.route '/dash', ->
    @wait Meteor.subscribe "allQuizzes"
    
    if @ready()
        @render "dashboard"
    else
        @render "loading"

if Meteor.isClient
    Template.dashboard.helpers
        hasCorrectAnswer: -> _.isNumber Template.currentData().correctAnswer
        quizzes: -> Quizzes.find {}
    
    Template.dashboard.events
        "click #new": (evt) ->
            id = Quizzes.insert({name: "New Quiz",lastmod: new Date()})
            Router.go "/edit/#{id}"
