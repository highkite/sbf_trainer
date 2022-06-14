module QuestionHandler  exposing (questionView)

import String
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Messages exposing (CurQuest, Msg(..), AnswerState(..))

import Array exposing (Array, fromList)
import List exposing (head, tail)

questionView : Maybe CurQuest -> Html Msg
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
                        , div[] (answersq (Just cq.randomization) cq cq.question.answers)
                ]]]]]]
            Nothing ->
                text "No question available"

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
                                        (div[class "btn btn-outline-secondary bg-success", style "margin-top" "5px", onClick (SelectAnswer hl)] [text ((String.fromInt hl) ++ val)]) :: answersq (tail lstl) cq lstans
                                    Incorrect ->
                                        (div[class "btn btn-outline-secondary bg-danger", style "margin-top" "5px", onClick (SelectAnswer hl)] [text ((String.fromInt hl) ++ val)]) :: answersq (tail lstl) cq lstans
                                    NotSet ->
                                        (div[class "btn btn-outline-secondary", style "margin-top" "5px", onClick (SelectAnswer hl)] [text ((String.fromInt hl) ++ val)]) :: answersq (tail lstl) cq lstans
                            else
                                (div[class "btn btn-outline-secondary", style "margin-top" "5px", onClick (SelectAnswer hl)] [text ((String.fromInt hl) ++ val)]) :: answersq (tail lstl) cq lstans
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
