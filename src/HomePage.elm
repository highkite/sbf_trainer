port module HomePage exposing (main, save, doload)

import Browser

import Process
import Debug
import Random
import Task
import Date exposing (today, toIsoString, Unit(..), add, fromIsoString, compare)
import Http exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import List exposing (head, isEmpty, tail, range, length)
import Random.List exposing (shuffle)

import MenuBar exposing (menuBar)
import StartUp exposing (startUp)

import Json.Encode as Encode exposing (Value, int, string, object)
import Json.Decode as JD exposing (Decoder, Error(..), decodeString, list, string, int)
import DataHandler exposing (fetchQuestions, learnProgressDecoder)

import SideNav exposing (nav)

import QuestionHandler exposing (questionView)

import Messages exposing (Msg(..), LearnData, Model, CurQuest, QuestionLearnProgress, Question, LearnProgress, AnswerState(..))


port save : String -> Cmd msg
port load : (String -> msg) -> Sub msg
port doload : () -> Cmd msg

initialModel : () -> (Model, Cmd Msg)
initialModel _ =
        ({ page_state = 0, learnData = [], learnProgress = [], errorMessage = Nothing, currentDate = "", currentQuestion = Nothing, showSidePanel = False}, Cmd.batch [today |> Task.perform ReadDate, fetchQuestions, doload()])

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

phaseOneDue : String -> String -> Bool
phaseOneDue today timestamp =
        case (fromIsoString today) of
                Ok today_date ->
                        case (fromIsoString timestamp) of
                                Ok ts ->
                                        Date.compare today_date (add Days 1 ts) == GT
                                Err value ->
                                        False
                Err value ->
                        False

phaseTwoDue : String -> String -> Bool
phaseTwoDue today timestamp =
        case (fromIsoString today) of
                Ok today_date ->
                        case (fromIsoString timestamp) of
                                Ok ts ->
                                        Date.compare today_date (add Days 3 ts) == GT
                                Err value ->
                                        False
                Err value ->
                        False

phaseThreeDue : String -> String -> Bool
phaseThreeDue today timestamp =
        case (fromIsoString today) of
                Ok today_date ->
                        case (fromIsoString timestamp) of
                                Ok ts ->
                                        Date.compare today_date (add Days 9 ts) == GT
                                Err value ->
                                        False
                Err value ->
                        False

phaseFourDue : String -> String -> Bool
phaseFourDue today timestamp =
        case (fromIsoString today) of
                Ok today_date ->
                        case (fromIsoString timestamp) of
                                Ok ts ->
                                        Date.compare today_date (add Days 29 ts) == GT
                                Err value ->
                                        False
                Err value ->
                        False

phaseFiveDue : String -> String -> Bool
phaseFiveDue today timestamp =
        case (fromIsoString today) of
                Ok today_date ->
                        case (fromIsoString timestamp) of
                                Ok ts ->
                                        Date.compare today_date (add Days 90 ts) == GT
                                Err value ->
                                        False
                Err value ->
                        False

filterLearnProgress : Model -> Maybe LearnProgress -> LearnProgress
filterLearnProgress model lpst =
        case lpst of
                Just lpstl ->
                        case (head lpstl) of
                                Just headel ->
                                        case headel.level of
                                                0 ->
                                                        headel :: filterLearnProgress model (tail lpstl)
                                                1 ->
                                                        if phaseOneDue model.currentDate headel.timestamp then
                                                                headel :: filterLearnProgress model (tail lpstl)
                                                        else
                                                                filterLearnProgress model (tail lpstl)
                                                2 ->
                                                        if phaseTwoDue model.currentDate headel.timestamp then
                                                                headel :: filterLearnProgress model (tail lpstl)
                                                        else
                                                                filterLearnProgress model (tail lpstl)
                                                3 ->
                                                        if phaseThreeDue model.currentDate headel.timestamp then
                                                                headel :: filterLearnProgress model (tail lpstl)
                                                        else
                                                                filterLearnProgress model (tail lpstl)
                                                4 ->
                                                        if phaseFourDue model.currentDate headel.timestamp then
                                                                headel :: filterLearnProgress model (tail lpstl)
                                                        else
                                                                filterLearnProgress model (tail lpstl)
                                                5 ->
                                                        if phaseFiveDue model.currentDate headel.timestamp then
                                                                headel :: filterLearnProgress model (tail lpstl)
                                                        else
                                                                filterLearnProgress model (tail lpstl)

                                                _ ->
                                                        filterLearnProgress model (tail lpstl)
                                Nothing ->
                                        []
                Nothing ->
                        []

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

                GelloView ->
                        let
                            populated_model = populateModel model
                            filtered_list = filterLearnProgress model (Just populated_model.learnProgress)
                            model_populated_model = { model | learnProgress = filtered_list, page_state = 1}
                        in
                        (model_populated_model, Random.generate ShuffleLearnProgress (shuffle model_populated_model.learnProgress))

                ReadDate time ->
                        ({ model | currentDate = toIsoString time }, Cmd.none)

                SendHttpRequest ->
                        (model, fetchQuestions)

                DataReceived (Ok learningData) ->
                        ({ model | learnData = learningData }, Cmd.none )

                DataReceived (Err httpError) ->
                        ( { model | errorMessage = Just (buildErrorMessage httpError) }
                            , Cmd.none
                            )

                SaveLocalStorage ->
                      (model , save (Encode.encode 0 (encodeJSON model.learnProgress)))

                DoLoadLocalStorage ->
                      (model , doload ())

                Load value ->
                        case (decodeString learnProgressDecoder value) of
                                Ok val ->
                                        let
                                            new_model = {model | learnProgress = val }
                                            populated_model = populateModel new_model
                                            filtered_list = filterLearnProgress model (Just populated_model.learnProgress)
                                            model_populated_model = { model | learnProgress = filtered_list }
                                        in
                                        (model_populated_model, Random.generate ShuffleLearnProgress (shuffle model_populated_model.learnProgress))
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

                ShowResultTimeout ->
                        case model.currentQuestion of
                                Just cq ->
                                        let
                                            new_cq = {cq | correct = NotSet}
                                            new_model = { model | currentQuestion = Just new_cq }
                                        in
                                        chooseQuestion new_model
                                Nothing ->
                                        chooseQuestion model

                SelectAnswer index ->
                        case model.currentQuestion of
                                Just cq ->
                                        -- check result and show correct result for a second or two
                                        if index == 0 then
                                                -- colorize green
                                                let
                                                    new_cq = {cq | correct = Correct}
                                                    new_learn_progress = increaseLevel (Just model.learnProgress) model cq
                                                in
                                                --( { model | currentQuestion = Just new_cq, learnProgress = new_learn_progress}, Process.sleep 500 |> Task.perform (always ShowResultTimeout))
                                                ( { model | currentQuestion = Just new_cq, learnProgress = new_learn_progress}, Cmd.batch [save (Encode.encode 0 (encodeJSON new_learn_progress)), Process.sleep 500 |> Task.perform (always ShowResultTimeout) ] )
                                        else
                                                -- colorize red
                                                let
                                                    new_cq = {cq | correct = Incorrect}
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
                                                                ({ model | currentQuestion = Just {index = cq.index + 1, progress = val, question = qst, randomization = rands, correct = NotSet}}, Random.generate RandomizeRandomization (shuffle rands))
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
                                                                ({ model | currentQuestion = Just {index = 0, progress = val, question = qst, randomization = rands, correct = NotSet}}, Random.generate RandomizeRandomization (shuffle rands))
                                                        Nothing ->
                                                                ({ model | currentQuestion = Nothing}, Cmd.none)
                                        Nothing ->
                                                ({ model | currentQuestion = Nothing}, Cmd.none)

encodeQJSON : QuestionLearnProgress -> Encode.Value
encodeQJSON lp =
        Encode.object
                [ ("ide", Encode.int lp.ide)
                , ("level", Encode.int lp.level)
                , ("timestamp", Encode.string lp.timestamp)
                ]

encodeJSON : LearnProgress -> Encode.Value
encodeJSON lp =
        Encode.list encodeQJSON lp

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
