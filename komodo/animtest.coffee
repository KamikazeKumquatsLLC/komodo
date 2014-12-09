Router.route "/animtest", ->
    @layout ""
    @render "animtest"

if Meteor.isClient
    Template.animtest.rendered = ->
        $("*[data-initial-properties]").each ->
            $(@).velocity
                properties: JSON.parse @dataset.initialProperties
                options:
                    duration: 0
    
    Template.animtest.events
        "click .anim-test-wrapper": ->
            $("*[data-initial-properties]").each ->
                $(@).velocity
                    properties: JSON.parse @dataset.initialProperties
                    options:
                        duration: 0
            
            row = (n) -> ->
                $.Velocity.animate
                    elements: document.querySelectorAll(".row#{n}")
                    properties:
                        scaleY: "+=2"
                        translateY: "-=52"
                        opacity: 1
            tri = (n) -> ->
                $.Velocity.animate
                    elements: document.querySelectorAll(".row1 :nth-child(#{n})")
                    properties:
                        scale: "+=2"
                        translateX: "-=15"
                        translateY: "-=26"
                        opacity: 1
            
            $.Velocity.animate
                elements: document.querySelectorAll ".row1 :first-child"
                properties:
                    opacity: 1
            .then tri 2
            .then tri 3
            .then tri 4
            .then tri 5
            .then row 2
            .then row 3
            .then row 4
            .then -> $("svg").velocity {opacity:0}, delay: 3000
