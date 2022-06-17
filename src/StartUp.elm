module StartUp exposing (startUp)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)

import Messages exposing (Msg(..), Model, LearnProgress)
import List exposing (length, tail, head)

startUp : Model -> Html Msg
startUp model =
        let
            p_prog = procentualLearnProgress (Just model.learnProgress)
            n = length model.learnData
            int_progress = (p_prog // n) * 100
            float_progress = toFloat (p_prog) / toFloat (n)
        in
        div [class "jumbotron d-flex align-items-center min-vh-100"]
        [div [class "container"]
        [div [class "row"]
        [div [class "col-12"]
        [div [class "card text-center"]
        [div [class "card-body"][
                h5 [class "card-title"][text "SBF Binnen Training"]
                ,p [class "card-text"][
                        p [] [
                                text ("Available questions: " ++ String.fromInt (length model.learnData))
                        ]
                        ,p [] [
                                text "Starte jetzt dein Training"
                        ]
                        ,div[class "progress"][
                                div [class "progress-bar", style "width" (String.fromInt(int_progress) ++ "%"), ariaValueNow (toFloat int_progress), ariaValueMin 0, ariaValueMax 100][
                                        text (String.fromFloat(float_progress) ++ "%")
                                ]
                        ]
                ]
                ,a [class "btn btn-primary", onClick GelloView][
                        text "Start"
                ]
        ]]]]
        ,div [class "row", style "margin-top" "50px"] [
                div [class "col-12"] [
                                p [class "text-muted"] [
                                        small [] [text "Der Gesamtfortschritt bezieht sich auf den Anteil von Fragen, welche es in Level 5 geschafft haben und damit als 'gelernt' gelten."]
                                        ]
                                ,p [class "text-muted"] [
                                        small [] [text "Der Lernfortschritt wird direkt in Ihrem Browser gespeichert. Keine Daten werden an andere Dienste oder Server übermittelt. Sie können den Lernfortschritt über das Sidepanel resetten."]
                                        ]
                        ]
                ]
        ]]

procentualLearnProgress : Maybe LearnProgress -> Int
procentualLearnProgress lst =
        case lst of
                Just lstl ->
                        case (head lstl) of
                                Just headel ->
                                        if headel.level >= 5 then
                                                1 + procentualLearnProgress (tail lstl)
                                        else
                                                procentualLearnProgress (tail lstl)
                                Nothing ->
                                        0
                Nothing ->
                        0

