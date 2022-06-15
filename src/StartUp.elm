module StartUp exposing (startUp)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)

import Messages exposing (Msg(..), Model)
import List exposing (length)

startUp : Model -> Html Msg
startUp model =
        div [class "jumbotron d-flex align-items-center min-vh-100"]
        [div [class "container"]
        [div [class "row"]
        [div [class "col-12"]
        [div [class "card text-center"]
        [div [class "card-body"][
                h5 [class "card-title"][text "SBF Binnen Training"]
                ,p [class "card-text"][
                        text "Starte jetzt dein Training"
                        ,text ("Available questions: " ++ String.fromInt (length model.learnData))
                        ,div[class "progress"][
                                div [class "progress-bar", style "width" "25%", ariaValueNow 25, ariaValueMin 0, ariaValueMax 100][
                                        text "25%"
                                ]
                        ]
                ]
                ,a [class "btn btn-primary", onClick SendHttpRequest ][
                        text "Start"
                ]
        ]]]]]]