module StartUp exposing (startUp)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)

import Chart.Bar as Bar
import Scale.Color

import Messages exposing (Msg(..), Model, LearnProgress)
import QuestionSelectionLogic exposing (getDueQuestions, countLevel0, countLevel1, countLevel2, countLevel3, countLevel4, countLevel5)
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
                                input [type_ "checkbox", class "form-check-input", id "cbx_example_check_1", checked model.config.spez_fragen_binnen, onClick ToggleSpezBinnen] [text "Sail"]
                                ,label [class "form-check-label", for "cbx_example_check_1"] [span [style "padding-left" "10px"] [text "Spezifische Fragen Binnen"]]
                        ]
                        ,p [] [
                                input [type_ "checkbox", class "form-check-input", id "cbx_example_check_2", checked model.config.spez_fragen_segeln, onClick ToggleSpezSegeln] [text "Sail"]
                                ,label [class "form-check-label", for "cbx_example_check_2"] [span [style "padding-left" "10px"] [text "Spezifische Fragen Segeln"]]
                        ]
                        ,p [] [
                                text ("Gesamtzahl verfügbarer Fragen: " ++ String.fromInt (length model.learnData))
                        ]
                        ,p [] [
                                text ("Heute fällige Fragen: " ++ String.fromInt (length (getDueQuestions model (Just model.learnProgress))))
                        ]
                        ,div [style "width" "100%"] [
                                (barChart model)
                        ]
                        ,div[class "progress"][
                                div [class "progress-bar", style "width" (String.fromInt(int_progress) ++ "%"), ariaValueNow (toFloat int_progress), ariaValueMin 0, ariaValueMax 100][
                                        text (String.fromFloat(float_progress) ++ "%")
                                ]
                        ]
                        ,p [] [
                                text "Starte jetzt dein Training"
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
                                ,p [class "text-muted"] [
                                        small [] [text "Die Fragen stammen von ", a [href "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Fragenkatalog-Binnen-node.html;jsessionid=F1E4A281E49882CE9F28B7F2275B0F98.server2t2"][text "ELWIS"], text "."]
                                ]
                        ]
                ]
                ]
        ]]

data : Model ->
    List
        { groupLabel : String
        , x : String
        , y : Float
        }

data model =
    [ { groupLabel = "Level"
      , x = "Level 0"
      , y = countLevel0 (Just model.learnProgress)
      }
    , { groupLabel = "Level"
      , x = "Level 1"
      , y = countLevel1 (Just model.learnProgress)
      }
    , { groupLabel = "Level"
      , x = "Level 2"
      , y = countLevel2 (Just model.learnProgress)
      }
    , { groupLabel = "Level"
      , x = "Level 3"
      , y = countLevel3 (Just model.learnProgress)
      }
    , { groupLabel = "Level"
      , x = "Level 4"
      , y = countLevel4 (Just model.learnProgress)
      }
    , { groupLabel = "Level"
      , x = "Level 5"
      , y = countLevel5 (Just model.learnProgress)
      }
    ]

accessor =
    Bar.Accessor (.groupLabel >> Just) .x .y

barChart : Model -> Html msg
barChart model =
        Bar.init
            { margin =
                { top = 10
                , right = 10
                , bottom = 30
                , left = -500
                }
            , width = 500
            , height = 50
            }
            |> Bar.withOrientation Bar.horizontal
            |> Bar.withColorPalette Scale.Color.tableau10
            |> Bar.withYDomain (0, 100)
            |> Bar.hideAxis
            |> Bar.withStackedLayout Bar.diverging
            |> Bar.render ( (data model), accessor )

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

