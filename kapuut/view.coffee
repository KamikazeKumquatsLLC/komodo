Router.route "/view/:id", ->
    @wait Meteor.subscribe "everything"
    
    if @ready()
        @render "view", data: -> Quizzes.findOne @params.id
    else
        @render "loading"

if Meteor.isClient
    Template.view.helpers
        correctIndicator: ->
            correct = Template.parentData(1).correctAnswer is Template.parentData(1).answers.indexOf(Template.currentData())
            if correct
                "plus"
            else
                "minus"
