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

import List exposing (head, isEmpty, tail, range, length)
import Random.List exposing (shuffle)

import MenuBar exposing (menuBar)
import StartUp exposing (startUp)

import Json.Decode as JD exposing (Decoder, Error(..), decodeValue, list, string, int)
import DataHandler exposing (fetchQuestions, learnProgressDecoder)

import QuestionHandler exposing (questionView)

import Messages exposing (Msg(..), LearnData, Model, QuestionLearnProgress, Question, LearnProgress)


port save : String -> Cmd msg
port load : (JD.Value -> msg) -> Sub msg
port doload : () -> Cmd msg

initialModel : () -> (Model, Cmd Msg)
initialModel _ =
        ({ page_state = 0, learnData = [], learnProgress = [], errorMessage = Nothing, currentDate = "", currentQuestion = Nothing}, today |> Task.perform ReadDate)

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
                                ,questionView model.currentQuestion
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
                        let
                            new_model = { model | learnProgress = lPs }
                        in
                        chooseQuestion new_model


                RandomizeRandomization lst ->
                        case model.currentQuestion of
                                Just val ->
                                        let
                                            new_val = { val | randomization = lst }
                                        in
                                        ({model | currentQuestion = Just new_val }, Cmd.none)
                                Nothing ->
                                        (model, Cmd.none)


chooseQuestion : Model -> (Model, Cmd Msg)
chooseQuestion model =
                case model.currentQuestion of
                        Just cq ->
                                let
                                    selected_question = getElement (Just model.learnProgress) (cq.index + 1)
                                in
                                case selected_question of
                                        Just val ->
                                                let
                                                    mapped_question = learnProgressToQuestion (Just model.learnData) selected_question
                                                in
                                                case mapped_question of
                                                        Just qst ->
                                                                let
                                                                    rands = range 0 ((length qst.answers) - 1)
                                                                in
                                                                ({ model | currentQuestion = Just {index = cq.index + 1, progress = val, question = qst, randomization = rands}}, Random.generate RandomizeRandomization (shuffle rands))
                                                        Nothing ->
                                                                ({ model | currentQuestion = Nothing}, Cmd.none)
                                        Nothing ->
                                                ({ model | currentQuestion = Nothing}, Cmd.none)
                        Nothing ->
                                let
                                    selected_question = head model.learnProgress
                                in
                                case selected_question of
                                        Just val ->
                                                let
                                                    mapped_question = learnProgressToQuestion (Just model.learnData) selected_question
                                                in
                                                case mapped_question of
                                                        Just qst ->
                                                                let
                                                                    rands = range 0 ((length qst.answers) - 1)
                                                                in
                                                                ({ model | currentQuestion = Just {index = 0, progress = val, question = qst, randomization = rands}}, Random.generate RandomizeRandomization (shuffle rands))
                                                        Nothing ->
                                                                ({ model | currentQuestion = Nothing}, Cmd.none)
                                        Nothing ->
                                                ({ model | currentQuestion = Nothing}, Cmd.none)

getElement : Maybe LearnProgress -> Int -> Maybe QuestionLearnProgress
getElement lst ind =
        case lst of
                Just lstl ->
                        if ind > 0 then
                                getElement (tail lstl) (ind - 1)
                        else
                                head lstl
                Nothing ->
                        Nothing


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
