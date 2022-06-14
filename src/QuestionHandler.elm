module QuestionHandler  exposing (questionView)

import String
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Messages exposing (CurQuest)

import Array exposing (Array, fromList)
import List exposing (head, tail)

questionView : Maybe CurQuest -> Html msg
questionView curQ =
        case curQ of
            Just cq ->
                div [class "jumbotron d-flex align-items-center min-vh-100"]
                [div [class "container"]
                [div [class "row"]
                [div [class "col-12"]
                [div [class "card text-center"]
                [div [class "card-body"][
                        h5 [class "card-title"][text cq.question.question]
                        ,p [class "card-text"][
                                text "Wähle unter den folgenden Antworten aus:"
                        ]
                        , div[] (answersq (Just cq.randomization) cq.question.answers)
                ]]]]]]
            Nothing ->
                text "No question available"

answersq : Maybe (List Int) -> List String -> (List (Html msg))
answersq lst lstans =
    case lst of
        Just lstl ->
            case (head lstl) of
                Just hl ->
                    case (answerByIndex hl (Just lstans)) of
                        Just val ->
                            (div[class "btn btn-outline-secondary", style "margin-top" "5px"] [text ((String.fromInt hl) ++ val)]) :: answersq (tail lstl) lstans
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


--answers : List Int -> Maybe (Array String) -> (List (Html msg))
--answers ilst lst =
--        case lst of
--            Just lstl ->
--                case (head lstl) of
--                    Just qst ->
--                            (div[class "btn btn-outline-secondary", style "margin-top" "5px"] [text qst]) :: answers (tail lstl)
--                    Nothing ->
--                        []
--            Nothing ->
--                        []
