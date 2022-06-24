module QuestionHandler  exposing (questionView)

import String
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Messages exposing (CurQuest, Msg(..), AnswerState(..), Model)

import Array exposing (Array, fromList)
import List exposing (head, tail, length)

questionView : Model -> Maybe CurQuest -> Html Msg
questionView model curQ =
        case curQ of
            Just cq ->
                div [class "jumbotron d-flex align-items-center min-vh-100"]
                [div [class "container"]
                [div [class "row"]
                [div [class "col-12"]
                [div [class "card text-center"]
                [div [class "card-body"][
                        div [] [text (String.fromInt (cq.index + 1)), text " / ", text (String.fromInt (length model.learnProgress))]
                        ,h5 [class "card-title"][text cq.question.question]
                        , div [] [span [class "badge bg-secondary"] [text "Level: ", text (String.fromInt cq.progress.level)]]
                        ,if length cq.question.images > 0 then
                            div [] (showImages (Just cq.question.images))
                        else
                            text ""
                        ,p [class "card-text"][
                                text "Wähle unter den folgenden Antworten aus:"
                        ]
                        , div[] (answersq (Just cq.randomization) cq cq.question.answers)
                ]]]]
                ,div[class "row"] [div [class "col-12", style "text-align" "right", style "margin-top" "15px"] [a [class "btn btn-secondary", onClick Home] [text "Zurück"]]]
                ]]
            Nothing ->
                div [class "jumbotron d-flex align-items-center min-vh-100"] [
                    div [class "container"] [
                        div [class "row"] [
                            div [class "col-12"] [
                                div [class "card text-center"] [
                                    div [class "card-body"][
                                        h5 [class "card-title"][text "No questions available"]
                                    ]
                                ]
                            ]
                        ]
                        ,div[class "row"] [div [class "col-12", style "text-align" "right", style "margin-top" "15px"] [a [class "btn btn-secondary", onClick Home] [text "Zurück"]]]
                    ]
                ]

showImages : Maybe (List String) -> List (Html msg)
showImages lst =
    case lst of
        Just lstl ->
            case (head lstl) of
                Just headel ->
                    (img [src ("data_collector/" ++ headel)] []) :: showImages (tail lstl)
                Nothing ->
                    []
        Nothing ->
            []


answersq : Maybe (List Int) -> CurQuest -> List String -> (List (Html Msg))
answersq lst cq lstans =
    case lst of
        Just lstl ->
            case (head lstl) of
                Just hl ->
                    case (answerByIndex hl (Just lstans)) of
                        Just val ->
                            if hl == 0 then
                                case cq.correct of
                                    Correct ->
                                        (div[class "btn btn-outline-secondary bg-success", style "margin-top" "5px", onClick (SelectAnswer hl)] [text val]) :: answersq (tail lstl) cq lstans
                                    Incorrect ->
                                        (div[class "btn btn-outline-secondary bg-danger", style "margin-top" "5px", onClick (SelectAnswer hl)] [text val]) :: answersq (tail lstl) cq lstans
                                    NotSet ->
                                        (div[class "btn btn-outline-secondary", style "margin-top" "5px", onClick (SelectAnswer hl)] [text val]) :: answersq (tail lstl) cq lstans
                            else
                                (div[class "btn btn-outline-secondary", style "margin-top" "5px", onClick (SelectAnswer hl)] [text val]) :: answersq (tail lstl) cq lstans
                        Nothing ->
                            []
                Nothing ->
                    []
        Nothing ->
            []

answerByIndex : Int -> Maybe (List String) -> Maybe String
answerByIndex index lst =
    case lst of
        Just lstl ->
            if index > 0 then
                answerByIndex (index - 1) (tail lstl)
            else
                head lstl
        Nothing ->
            Nothing
