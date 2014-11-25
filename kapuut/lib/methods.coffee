Meteor.methods
    log: (msg) ->
        check(msg, String)
        console.log(msg)

@powerLog = (args...) -> Meteor.call("log", args...)
