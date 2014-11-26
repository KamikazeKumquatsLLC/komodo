Router.route "/edit/:id", ->
    @wait Meteor.subscribe "quiz", @params.id
    
    if @ready()
        Session.set "quizid", @params.id
        if Quizzes.findOne(@params.id).owner isnt Meteor.userId()
            @redirect "/view/#{@params.id}"
        @render "edit", data: -> Quizzes.findOne @params.id
    else
        @render "loading"

if Meteor.isClient
    getQuiz = -> Quizzes.findOne Session.get "quizid"
    getQuestion = -> getQuiz().questions[Session.get "selectedQuestion"]
    hasCorrectAnswer = -> _.isNumber getQuestion().correctAnswer
    hasAnswers = -> _.isArray getQuestion().answers
    
    Template.edit.helpers
        currentQuestion: -> getQuestion()
        i: -> getQuestion().answers?.indexOf(Template.currentData()) + 1
        questionIdx: -> Template.parentData(1).questions.indexOf(Template.currentData()) + 1
        checked: ->
            if Template.parentData(1).correctAnswer is Template.parentData(1).answers?.indexOf(Template.currentData())
                "checked"
        quiz: ->
            if hasCorrectAnswer()
                "selected"
        survey: ->
            if hasAnswers() and not hasCorrectAnswer()
                "selected"
        textonly: ->
            if not hasAnswers()
                "selected"
        first: -> Session.equals "selectedQuestion", 0
        last: -> Session.equals "selectedQuestion", Template.currentData().questions.length - 1
        active: ->
            if Session.equals "selectedQuestion", Template.parentData(1).questions.indexOf(Template.currentData())
                "active"
    
    Template.edit.events
        "click .pagination li.prev": (evt) ->
            Session.set "selectedQuestion", Session.get("selectedQuestion") - 1
        "click .pagination li.next": (evt) ->
            Session.set "selectedQuestion", Session.get("selectedQuestion") + 1
        "click .pagination li.page": (evt) ->
            Session.set "selectedQuestion", parseInt(evt.target.innerText) - 1
        "click #newQuestion": (evt) ->
            Quizzes.update getQuiz()._id, $push: questions: {correctAnswer: 0, answers: [""]}
            Session.set "selectedQuestion", getQuiz().questions.length - 1
        "click #deleteQuestion": (evt) ->
            setModifier = $set: {}
            setModifier.$set["questions.#{Session.get("selectedQuestion")}"] = {NeedsDeleting:yes}
            Quizzes.update getQuiz()._id, setModifier
            Quizzes.update getQuiz()._id, $pull: questions: {NeedsDeleting:yes}
            Session.set "selectedQuestion", Session.get("selectedQuestion") - 1
    
    Template.edit.rendered = ->
        # This lock was a pain to figure out.
        # Since setValue() fires "change", we need to avoid saving partially loaded text.
        # Since Quizzes.update changes getQuestion(), we need to avoid setting the text we just saved and resetting the cursor position.
        locked = no
        questionEditor = ace.edit "questionEdit"
        questionEditor.setTheme("ace/theme/clouds")
        questionEditor.getSession().setMode("ace/mode/markdown")
        questionEditor.getSession().on "change", (evt) ->
            unless locked
                locked = yes
                setOperator = lastmod: new Date()
                setOperator["questions.#{Session.get("selectedQuestion")}.text"] = questionEditor.getValue()
                Quizzes.update getQuiz()._id, $set: setOperator
        
        Tracker.autorun ->
            if locked
                console.log getQuestion()
            else
                locked = yes
                questionEditor.setValue getQuestion().text, 1
            locked = no
    
    quizPropChange = (selector, name) ->
        result = {}
        result["change #{selector}"] = (evt) ->
            setOperator = lastmod: new Date()
            setOperator[name] = $(selector).val()
            Quizzes.update getQuiz()._id, $set: setOperator
        Template.edit.events result
    
    quizPropChange "#inputName", "name"
    quizPropChange "#inputDescription", "description"
    
    Template.edit.events
        "change .inputCorrect": (evt) ->
            setOperator = lastmod: new Date()
            setOperator["questions.#{Session.get("selectedQuestion")}.correctAnswer"] = parseInt(evt.target.id.replace("inputCorrect", "")) - 1
            Quizzes.update getQuiz()._id, $set: setOperator
        "click #newAnswer": (evt) ->
            Quizzes.update getQuiz()._id, $set: lastmod: new Date()
            pushOperator = {}
            pushOperator["questions.#{Session.get("selectedQuestion")}.answers"] = "Sample Answer"
            Quizzes.update getQuiz()._id, $push: pushOperator
        "click .delete": (evt) ->
            setOperator = lastmod: new Date()
            setOperator["questions.#{Session.get("selectedQuestion")}.answers.#{parseInt(evt.target.id.replace("delete", "")) - 1}"] = {NeedsDeleting:yes}
            Quizzes.update getQuiz()._id, $set: setOperator
            pullOperator = {}
            pullOperator["questions.#{Session.get("selectedQuestion")}.answers"] = {NeedsDeleting:yes}
            Quizzes.update getQuiz()._id, $pull: pullOperator
        "change .inputAnswer": (evt) ->
            setOperator = lastmod: new Date()
            setOperator["questions.#{Session.get("selectedQuestion")}.answers.#{parseInt(evt.target.id.replace("inputAnswer", "")) - 1}"] = evt.target.value
            Quizzes.update getQuiz()._id, $set: setOperator
        "change #inputType": (evt) ->
            oldQuestion = getQuestion()
            modifier = $set: {lastmod: new Date()}, $unset: {}
            switch $("#inputType").val()
                when "One right answer (quiz-style)"
                    unless _(oldQuestion).has("correctAnswer")
                        modifier.$set["questions.#{Session.get("selectedQuestion")}.correctAnswer"] = 0
                    unless _(oldQuestion).has("answers")
                        modifier.$set["questions.#{Session.get("selectedQuestion")}.answers"] = [""]
                when "No right answers (survey-style)"
                    if _(oldQuestion).has("correctAnswer")
                        modifier.$unset["questions.#{Session.get("selectedQuestion")}.correctAnswer"] = yes
                    unless _(oldQuestion).has("answers")
                        modifier.$set["questions.#{Session.get("selectedQuestion")}.answers"] = [""]
                when "No answers (text only)"
                    if _(oldQuestion).has("correctAnswer")
                        modifier.$unset["questions.#{Session.get("selectedQuestion")}.correctAnswer"] = yes
                    if _(oldQuestion).has("answers")
                        modifier.$unset["questions.#{Session.get("selectedQuestion")}.answers"] = yes
            Quizzes.update getQuiz()._id, modifier
        "click #deleteQuiz": (evt) ->
            Quizzes.remove getQuiz()._id
            Router.go "/dash"
    
    Meteor.startup ->
        Session.setDefault "selectedQuestion", 0
        
        Tracker.autorun ->
            Quizzes.find(Session.get("quizid")).observeChanges
                changed: (id, fields) ->
                    unless _.isEmpty _.omit fields, "lastmod"
                        Quizzes.update id, $set: lastmod: new Date()
