Router.route "/animtest", ->
    @layout ""
    @render "animtest"

if Meteor.isClient
    Template.animtest.rendered = ->
        $("g[data-initial-properties], polygon[data-initial-properties]").each ->
            $(@).velocity
                properties: JSON.parse @dataset.initialProperties
                options:
                    duration: 0
    
    Template.animtest.events
        "click svg": ->
            $("g[data-initial-properties], polygon[data-initial-properties]").each ->
                $(@).velocity
                    properties: JSON.parse @dataset.initialProperties
                    options:
                        duration: 0
            runRow4 = ->
                $(".row4").velocity
                    properties:
                        scaleY: "+=2"
                        translateY: "-=52"
                        opacity: 1
            runRow3 = ->
                $(".row3").velocity
                    properties:
                        scaleY: "+=2"
                        translateY: "-=52"
                        opacity: 1
                    options:
                        complete: runRow4
            runRow2 = -> $(".row2").velocity
                properties:
                    scaleY: "+=2"
                    translateY: "-=52"
                    opacity: 1
                options:
                    complete: runRow3
            runTri5 = -> $(".row1 :nth-child(5)").velocity
                properties:
                    scale: "+=2"
                    translateX: "-=15"
                    translateY: "-=26"
                    opacity: 1
                options:
                    complete: runRow2
            runTri4 = -> $(".row1 :nth-child(4)").velocity
                properties:
                    scale: "+=2"
                    translateX: "-=15"
                    translateY: "-=26"
                    opacity: 1
                options:
                    complete: runTri5
            runTri3 = -> $(".row1 :nth-child(3)").velocity
                properties:
                    scale: "+=2"
                    translateX: "-=15"
                    translateY: "-=26"
                    opacity: 1
                options:
                    complete: runTri4
            runTri2 = -> $(".row1 :nth-child(2)").velocity
                properties:
                    scale: "+=2"
                    translateX: "-=15"
                    translateY: "-=26"
                    opacity: 1
                options:
                    complete: runTri3
            runTri2()
