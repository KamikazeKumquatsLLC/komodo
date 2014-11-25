Router.route "/host/:id", ->
    @render "host", data: -> Quizzes.findOne @params.id

if Meteor.isClient
    # do client stuff
