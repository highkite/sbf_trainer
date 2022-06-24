port module HomePage exposing (main, save, doload, doloadConfig, saveConfig)

import Browser

import Process
import Debug
import Random
import Task
import Date exposing (today, toIsoString, Unit(..))
import Http exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import List exposing (head, tail)
import Random.List exposing (shuffle)

import MenuBar exposing (menuBar)
import StartUp exposing (startUp)

import Json.Encode as Encode exposing (Value, int, string, object)
import Json.Decode as JD exposing (Decoder, Error(..), decodeString, list, string, int)
import DataHandler exposing (fetchQuestions, learnProgressDecoder, configDecoder, fetchSpezBinnen, fetchSpezSegeln)

import QuestionSelectionLogic exposing (mergeModel, takeNextQuestion)

import SideNav exposing (nav)

import QuestionHandler exposing (questionView)

import Messages exposing (Msg(..), LearnData, Model, CurQuest, QuestionLearnProgress, Question, LearnProgress, AnswerState(..), Id, Config)


port save : String -> Cmd msg
port saveConfig : String -> Cmd msg
port load : (String -> msg) -> Sub msg
port loadConfig : (String -> msg) -> Sub msg
port doload : () -> Cmd msg
port doloadConfig : () -> Cmd msg

initialModel : () -> (Model, Cmd Msg)
initialModel _ =
        ({ page_state = 0, learnData = [], learnProgress = [], errorMessage = Nothing, currentDate = "", currentQuestion = Nothing, showSidePanel = False, config = {spez_fragen_binnen = False, spez_fragen_segeln = False}}, Cmd.batch [today |> Task.perform ReadDate, doloadConfig()])

view : Model -> Html Msg
view model =
        case model.page_state of
                0 ->
                        div []
                        [
                                if model.showSidePanel then
                                        SideNav.nav model
                                else
                                        text ""
                                ,menuBar
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
                                if model.showSidePanel then
                                        SideNav.nav model
                                else
                                        text ""
                                ,menuBar
                                ,questionView model model.currentQuestion
                        ]
                _ ->
                        div []
                        [
                                menuBar
                                ,text ("Gello")
                        ]

invertBool : Bool -> Bool
invertBool value =
        if value == True then
                False
        else
                True

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
        case msg of
                ToggleSidePanel ->
                        ({ model | showSidePanel = invertBool model.showSidePanel }, Cmd.none)

                DeleteLearningProgress ->
                        let
                            new_model = { model | learnProgress = [], showSidePanel = False}
                        in
                        (new_model , save (Encode.encode 0 (encodeJSON new_model.learnProgress)))

                StartUpView ->
                        ({ model | page_state = 0 }, Cmd.none)

                Home ->
                        ({ model | page_state = 0, currentQuestion = Nothing}, Cmd.none)

                GelloView ->
                        case model.currentQuestion of
                                Just cquest ->
                                        ({model | currentQuestion = takeNextQuestion model model.learnProgress cquest.index, page_state = 1}, Cmd.none)

                                Nothing ->
                                        ({model | currentQuestion = takeNextQuestion model model.learnProgress 0, page_state = 1}, Cmd.none)

                ReadDate time ->
                        ({ model | currentDate = toIsoString time }, Cmd.none)

                SendHttpRequest ->
                        (model, fetchQuestions)

                DataReceived (Ok learningData) ->
                        ({ model | learnData = learningData }, fetchSpezBinnen model)

                DataReceived (Err httpError) ->
                        ( { model | errorMessage = Just (buildErrorMessage httpError) }
                            , Cmd.none
                            )

                BinnenDataReceived (Ok learningData) ->
                        ({ model | learnData = (model.learnData ++ learningData) }, fetchSpezSegeln model)

                BinnenDataReceived (Err httpError) ->
                        ( { model | errorMessage = Just (buildErrorMessage httpError) }
                            , Cmd.none
                            )

                SegelnDataReceived (Ok learningData) ->
                        ({ model | learnData = (model.learnData ++ learningData) }, doload() )

                SegelnDataReceived (Err httpError) ->
                        ( { model | errorMessage = Just (buildErrorMessage httpError) }
                            , Cmd.none
                            )

                SaveLocalStorage ->
                      (model , save (Encode.encode 0 (encodeJSON model.learnProgress)))

                ToggleSpezBinnen ->
                        let
                            cfg = model.config
                            new_config = {cfg | spez_fragen_binnen = invertBool model.config.spez_fragen_binnen}
                            new_model = {model | config = new_config}
                        in
                        (new_model, Cmd.batch[saveConfig (Encode.encode 0 (encodeConfig new_model.config)), fetchQuestions])

                ToggleSpezSegeln ->
                        let
                            cfg = model.config
                            new_config = {cfg | spez_fragen_segeln = invertBool model.config.spez_fragen_segeln}
                            new_model = {model | config = new_config}
                        in
                        (new_model, Cmd.batch[saveConfig (Encode.encode 0 (encodeConfig new_model.config)), fetchQuestions])

                SaveConfig ->
                        (model, saveConfig (Encode.encode 0 (encodeConfig model.config)))

                DoLoadLocalStorage ->
                      (model , doload ())

                DoLoadConfig ->
                        (model, doloadConfig())

                LoadConfig value ->
                        case (decodeString configDecoder value) of
                                Ok val ->
                                      ({ model | config = val }, fetchQuestions)
                                Err errMsg ->
                                        case errMsg of
                                                JD.Field erVal err ->
                                                        Debug.log "Error when loading config"
                                                        (model, Cmd.none)

                                                JD.Index nbr err ->
                                                        Debug.log "Error when loading config"
                                                        (model, Cmd.none)

                                                JD.Failure erVal val ->
                                                      ({ model | config = {spez_fragen_binnen = False, spez_fragen_segeln = False} }, fetchQuestions)
                                                _ ->
                                                        (model, Cmd.none)

                Load value ->
                        case (decodeString learnProgressDecoder value) of
                                Ok val ->
                                        let
                                            new_model = {model | learnProgress = val}
                                            populated_model = mergeModel new_model (Just model.learnData)
                                        in
                                        (populated_model, Random.generate ShuffleLearnProgress (shuffle populated_model.learnProgress))
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
                                                            new_model = mergeModel model (Just model.learnData)
                                                        in
                                                        (new_model, Cmd.batch [save (Encode.encode 0 (encodeJSON new_model.learnProgress)), Random.generate ShuffleLearnProgress (shuffle new_model.learnProgress)])
                                                _ ->
                                                        (model, Cmd.none)

                ShuffleLearnProgress lPs ->
                        let
                            new_model = { model | learnProgress = lPs }
                        in
                        (new_model, Cmd.none)

                RandomizeRandomization lst ->
                        case model.currentQuestion of
                                Just val ->
                                        let
                                            new_val = { val | randomization = lst }
                                        in
                                        ({model | currentQuestion = Just new_val }, Cmd.none)
                                Nothing ->
                                        (model, Cmd.none)

                ShowResultTimeout ->
                        case model.currentQuestion of
                                Just cq ->
                                        let
                                            --new_cq = {cq | correct = NotSet}
                                            new_cq = takeNextQuestion model model.learnProgress cq.index
                                            new_model = { model | currentQuestion = new_cq }
                                        in
                                        (new_model, Cmd.none)
                                Nothing ->
                                        (model, Cmd.none)

                SelectAnswer index ->
                        case model.currentQuestion of
                                Just cq ->
                                        -- check result and show correct result for a second or two
                                        if index == 0 then
                                                -- colorize green
                                                let
                                                    new_cq = {cq | correct = Correct, index = (cq.index + 1)}
                                                    new_learn_progress = increaseLevel (Just model.learnProgress) model cq
                                                in
                                                --( { model | currentQuestion = Just new_cq, learnProgress = new_learn_progress}, Process.sleep 500 |> Task.perform (always ShowResultTimeout))
                                                ( { model | currentQuestion = Just new_cq, learnProgress = new_learn_progress}, Cmd.batch [save (Encode.encode 0 (encodeJSON new_learn_progress)), Process.sleep 500 |> Task.perform (always ShowResultTimeout) ] )
                                        else
                                                -- colorize red
                                                let
                                                    new_cq = {cq | correct = Incorrect, index = (cq.index + 1)}
                                                    new_learn_progress = resetLevel (Just model.learnProgress) model cq
                                                in
                                                --( { model | currentQuestion = Just new_cq, learnProgress = new_learn_progress}, Process.sleep 500 |> Task.perform (always ShowResultTimeout))
                                                ( { model | currentQuestion = Just new_cq, learnProgress = new_learn_progress}, Cmd.batch [save (Encode.encode 0 (encodeJSON new_learn_progress)), Process.sleep 1500 |> Task.perform (always ShowResultTimeout) ])
                                Nothing ->
                                        (model, Cmd.none)

                        -- increase or reset level
                        -- store update to browser memory
                        -- select next question

resetLevel : Maybe LearnProgress -> Model -> CurQuest -> LearnProgress
resetLevel lst model cq =
        case lst of
                Just lstl ->
                        case (head lstl) of
                                Just headel ->
                                        if headel.ide == cq.progress.ide then
                                                let
                                                    new_head_el = {headel | level = 0, timestamp = model.currentDate}
                                                in
                                                new_head_el :: (increaseLevel (tail lstl) model cq)
                                        else
                                                headel :: (increaseLevel (tail lstl) model cq)
                                Nothing ->
                                        lstl

                Nothing ->
                        []

increaseLevel : Maybe LearnProgress -> Model -> CurQuest -> LearnProgress
increaseLevel lst model cq =
        case lst of
                Just lstl ->
                        case (head lstl) of
                                Just headel ->
                                        if headel.ide == cq.progress.ide then
                                                let
                                                    new_head_el = {headel | level = (headel.level + 1), timestamp = model.currentDate}
                                                in
                                                new_head_el :: (increaseLevel (tail lstl) model cq)
                                        else
                                                headel :: (increaseLevel (tail lstl) model cq)
                                Nothing ->
                                        lstl

                Nothing ->
                        []

encodeID : Id -> Encode.Value
encodeID id =
        Encode.object
        [ ("ide", Encode.int id.ide)
        , ("questionType", Encode.int id.questionType)
        ]

encodeQJSON : QuestionLearnProgress -> Encode.Value
encodeQJSON lp =
        Encode.object
                [ ("ide", encodeID lp.ide)
                , ("level", Encode.int lp.level)
                , ("timestamp", Encode.string lp.timestamp)
                ]

encodeConfig : Config -> Encode.Value
encodeConfig cfg =
        Encode.object
                [ ("spez_fragen_binnen", Encode.bool cfg.spez_fragen_binnen)
                , ("spez_fragen_segeln", Encode.bool cfg.spez_fragen_segeln)
                ]

encodeJSON : LearnProgress -> Encode.Value
encodeJSON lp =
        Encode.list encodeQJSON lp

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
subscriptions model = Sub.batch [load Load, loadConfig LoadConfig]

main : Program () Model Msg
main =
        Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
