Router.route '/dash', ->
    #if Meteor.user()
        @render "dashboard"
    #else
    #    @redirect "/welcome"

if Meteor.isClient
    Template.dashboard.helpers
        quizzes: -> Quizzes.find {}
