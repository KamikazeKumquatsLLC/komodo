Router.route "/prehost/:id", ->
    @wait Meteor.subscribe "quiz", @params.id
    @wait Meteor.subscribe "gameIDs"
    
    if @ready()
        @render "prehost", data: -> Quizzes.findOne @params.id
    else
        @render "loading"

Meteor.methods
    host: (options) ->
        if not @userId
            throw new Meteor.Error("logged-out", "The user must be logged in to host a quiz")
        if not _.isObject(Quizzes.findOne(options.quiz))
            throw new Meteor.Error("no-such-quiz", "There's no quiz with the id provided")
        shortid = Math.floor(Math.random() * Math.pow(10, SHORTID_DIGITS))
        while LiveGames.findOne({shortid: shortid})?
            shortid = Math.floor(Math.random() * Math.pow(10, SHORTID_DIGITS))
        overrides =
            shortid: "#{shortid}"
            players: []
            answers: [[]]
            owner: @userId
            purgeby: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        LiveGames.insert _.extend options, overrides
        return shortid

if Meteor.isClient
    updateSegments = ->
        numTeamsUsed = $("#inputNumTeams").val() isnt ""
        teamSizeUsed = $("#inputTeamSize").val() isnt ""
        if numTeamsUsed
            $(".numTeams").attr("style", "")
            $(".teamSize").hide()
        else if teamSizeUsed
            $(".teamSize").attr("style", "")
            $(".numTeams").hide()
        else
            $(".numTeams").attr("style", "")
            $(".teamSize").attr("style", "")
    
    Template.prehost.events
        "keyup #inputNumTeams": updateSegments
        "keyup #inputTeamSize": updateSegments
        'click #begin': (evt) ->
            id = Router.current().params.id
            name = $("#inputName").val()
            countdown = parseInt $("#inputCountdownLength").val()
            expected = parseInt $("#inputExpectedPlayers").val()
            showGuessers = $("#inputShowGuessers:checked").length is 1
            allowLateAnswers = $("#inputAllowLateAnswers:checked").length is 1
            revealWithAllAnswers = $("#inputRevealWithAllAnswers:checked").length is 1
            teams = $("#inputTeams:checked").length is 1
            numTeams = parseInt $("#inputNumTeams").val()
            teamSize = parseInt $("#inputTeamSize").val()
            if countdown < 0 or countdown isnt parseInt "#{countdown}"
                console.log "Stuff broke!"
                countdown = 5
            options =
                quiz: id
                name: name
                countdownlength: countdown
                expected: expected
                showGuessers: showGuessers
                allowLateAnswers: allowLateAnswers
                revealWithAllAnswers: revealWithAllAnswers
                teams:
                    use: teams
                    num: numTeams
                    size: teamSize
            Meteor.call "host", options, (err, shortid) ->
                unless err
                    Router.go "/host/#{shortid}"
            return no
