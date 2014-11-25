Router.route '/dash', ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @render "dashboard"
    else
        @render "loading"

if Meteor.isClient
    Template.dashboard.helpers
        quizzes: -> Quizzes.find {}
