Router.route "/view/:id", ->
    @wait Meteor.subscribe "quiz", @params.id
    
    if @ready()
        @render "view", data: -> Quizzes.findOne @params.id
    else
        @render "loading"

if Meteor.isClient
    Template.view.helpers
        hasCorrectAnswer: -> _.isNumber Template.currentData().correctAnswer
        correctIndicator: ->
            correct = Template.parentData(1).correctAnswer is Template.parentData(1).answers.indexOf(Template.currentData())
            if correct
                "plus"
            else
                "minus"
