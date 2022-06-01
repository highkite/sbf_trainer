module QuestionHandler  exposing (questionView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Messages exposing (Question)

import List exposing (head, tail)

questionView : Maybe Question -> Html msg
questionView question =
        case question of
            Just message ->
                div [class "jumbotron d-flex align-items-center min-vh-100"]
                [div [class "container"]
                [div [class "row"]
                [div [class "col-12"]
                [div [class "card text-center"]
                [div [class "card-body"][
                        h5 [class "card-title"][text message.question]
                        ,p [class "card-text"][
                                text "Wähle unter den folgenden Antworten aus:"
                        ]
                        , div[] (answers (Maybe.Just message.answers))
                ]]]]]]
            Nothing ->
                text "No question available"

answers : Maybe (List String) -> (List (Html msg))
answers lst =
        case lst of
            Just lstl ->
                case (head lstl) of
                    Just qst ->
                            (div[class "btn btn-outline-secondary", style "margin-top" "5px"] [text qst]) :: answers (tail lstl)
                    Nothing ->
                        []
            Nothing ->
                        []
