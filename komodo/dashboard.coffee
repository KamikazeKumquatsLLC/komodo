Router.route '/dash', ->
    @wait Meteor.subscribe "allQuizzes"
    
    if @ready()
        @render "dashboard"
    else
        @render "loading"

if Meteor.isClient
    Template.dashboard.helpers
        hasCorrectAnswer: -> _.isNumber Template.currentData().correctAnswer
        quizzes: -> Quizzes.find {}, sort: [["lastmod", "desc"]]
    
    Template.dashboard.events
        "click #new": (evt) ->
            id = Quizzes.insert({name: "New Quiz",lastmod: new Date(), owner: Meteor.userId()})
            Router.go "/edit/#{id}"
