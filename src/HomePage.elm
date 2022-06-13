port module HomePage exposing (main, save, doload)

import Browser

import Debug
import Random
import Task
import Date exposing (today, toIsoString)
import Http exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import List exposing (head, isEmpty, tail)
import Random.List exposing (shuffle)

import MenuBar exposing (menuBar)
import StartUp exposing (startUp)

import Json.Decode as JD exposing (Decoder, Error(..), decodeValue, list, string, int)
import DataHandler exposing (fetchQuestions, learnProgressDecoder)

import QuestionHandler exposing (questionView)

import Messages exposing (Msg(..), LearnData, Model, QuestionLearnProgress, Question)


port save : String -> Cmd msg
port load : (JD.Value -> msg) -> Sub msg
port doload : () -> Cmd msg

initialModel : () -> (Model, Cmd Msg)
initialModel _ =
        ({ page_state = 0, learnData = [], learnProgress = [], errorMessage = Nothing, currentDate = ""}, today |> Task.perform ReadDate)

createQuestionLearnProgress : Maybe (List Question) -> Model -> Model
createQuestionLearnProgress lst model =
        case lst of
                Just lstl ->
                        case head lstl of
                                Just headel ->
                                        createQuestionLearnProgress (tail lstl) { model | learnProgress = { ide = headel.ide, level = 0, timestamp = model.currentDate } :: model.learnProgress }
                                Nothing ->
                                        model
                Nothing ->
                        model

populateModel : Model -> Model
populateModel model =
        case isEmpty(model.learnProgress) of
                True ->
                        createQuestionLearnProgress (Just model.learnData) model
                False ->
                        model

learnProgressToQuestion : Maybe LearnData -> Maybe QuestionLearnProgress -> Maybe Question
learnProgressToQuestion ld lp =
        case lp of
                Just lpl ->
                        case ld of
                                Just ldl ->
                                        case head ldl of
                                                Just headel ->
                                                        if headel.ide == lpl.ide then
                                                                Just headel
                                                        else
                                                                learnProgressToQuestion (tail ldl) lp
                                                Nothing ->
                                                        Nothing

                                Nothing ->
                                        Nothing
                Nothing ->
                        Nothing


view : Model -> Html Msg
view model =
        case model.page_state of
                0 ->
                        div []
                        [
                                menuBar
                                ,startUp model
                                ,case model.errorMessage of
                                        Just message ->
                                                text ("Error: " ++ message)
                                        Nothing ->
                                                text ""
                        ]
                1 ->
                        div []
                        [
                                menuBar
                                ,questionView (learnProgressToQuestion (Just model.learnData) (head model.learnProgress))
                        ]
                _ ->
                        div []
                        [
                                menuBar
                                ,text ("Gello")
                        ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
        case msg of
                StartUpView ->
                        ({ model | page_state = 0 }, Cmd.none)

                GelloView ->
                        ({ model | page_state = 1 }, Cmd.none)

                ReadDate time ->
                        ({ model | currentDate = toIsoString time }, Cmd.none)

                SendHttpRequest ->
                        (model, fetchQuestions)

                DataReceived (Ok learningData) ->
                        ({ model | learnData = learningData,page_state = 1 }, doload() )

                DataReceived (Err httpError) ->
                        ( { model | errorMessage = Just (buildErrorMessage httpError) }
                            , Cmd.none
                            )

                SaveLocalStorage ->
                      (model , save "abc")

                DoLoadLocalStorage ->
                      (model , doload ())

                Load value ->
                        case (decodeValue learnProgressDecoder value) of
                                Ok val ->
                                        (populateModel {model | learnProgress = val }, Random.generate ShuffleLearnProgress (shuffle model.learnProgress))
                                Err errMsg ->
                                        case errMsg of
                                                JD.Field erVal err ->
                                                        Debug.log "Error when loading learn progress"
                                                        (model, Cmd.none)

                                                JD.Index nbr err ->
                                                        Debug.log "Error when loading learn progress"
                                                        (model, Cmd.none)

                                                JD.Failure erVal val ->
                                                        let
                                                            new_model = populateModel model
                                                        in
                                                                (new_model, Random.generate ShuffleLearnProgress (shuffle new_model.learnProgress))
                                                _ ->
                                                        (model, Cmd.none)

                ShuffleLearnProgress lPs ->
                        Debug.log "shuffle"
                        ({ model | learnProgress = lPs }, Cmd.none)

buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message

subscriptions : Model -> Sub Msg
subscriptions model = load Load

main : Program () Model Msg
main =
        Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
