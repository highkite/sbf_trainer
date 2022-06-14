module Messages exposing (Msg(..), Question, LearnData, Model, QuestionLearnProgress, LearnProgress, CurQuest, AnswerState(..))
import Json.Decode as JD exposing (Value)

import Date exposing (Date)

import Http

type alias Question = {
        ide : Int
        , question : String
        , answers : List String
        , images : List String
        }

type alias LearnData =
        List Question

type alias QuestionLearnProgress = {
        ide : Int
        ,level : Int
        ,timestamp : String
        }

type alias LearnProgress =
        List QuestionLearnProgress

type Msg
        = StartUpView
        | GelloView
        | SendHttpRequest
        | DataReceived (Result Http.Error LearnData)
        | SaveLocalStorage
        | DoLoadLocalStorage
        | Load Value
        | ReadDate Date
        | ShuffleLearnProgress LearnProgress
        | RandomizeRandomization (List Int)
        | SelectAnswer Int
        | ShowResultTimeout

type AnswerState
        = Correct
        | Incorrect
        | NotSet

type alias CurQuest
        = {
                index : Int
                ,question : Question
                ,progress : QuestionLearnProgress
                ,randomization : List Int
                ,correct : AnswerState
        }

type alias Model =
        { page_state : Int
        , learnData : LearnData
        , learnProgress : LearnProgress
        , errorMessage : Maybe String
        , currentDate : String
        , currentQuestion : Maybe CurQuest
        }
