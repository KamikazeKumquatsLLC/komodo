Router.route "/view/:id", ->
    #if not Meteor.user()
    #    @redirect "/welcome"
    #else
        @render "view", data: -> Quizzes.findOne @params.id

if Meteor.isClient
    Template.view.helpers
        correctIndicator: ->
            correct = Template.parentData(1).correctAnswer is Template.parentData(1).answers.indexOf(Template.currentData())
            if correct
                "plus"
            else
                "minus"
