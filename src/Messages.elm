module Messages exposing (Msg(..), Question, LearnData, Model, QuestionLearnProgress, LearnProgress, CurQuest, AnswerState(..), Id, Config)
import Json.Decode as JD exposing (Value)

import Date exposing (Date)

import Http

type alias Config = {
        spez_fragen_binnen : Bool
        ,spez_fragen_segeln : Bool
        }

type alias Id = {
        ide : Int
        ,questionType : Int
        }

type alias Question = {
        ide : Id
        , question : String
        , answers : List String
        , images : List String
        }

type alias LearnData =
        List Question

type alias QuestionLearnProgress = {
        ide : Id
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
        | BinnenDataReceived (Result Http.Error LearnData)
        | SegelnDataReceived (Result Http.Error LearnData)
        | SaveLocalStorage
        | SaveConfig
        | DoLoadLocalStorage
        | Load String
        | LoadConfig String
        | DoLoadConfig
        | ReadDate Date
        | ShuffleLearnProgress LearnProgress
        | RandomizeRandomization (List Int)
        | SelectAnswer Int
        | ShowResultTimeout
        | ToggleSidePanel
        | DeleteLearningProgress
        | ToggleSpezBinnen
        | ToggleSpezSegeln

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
        , showSidePanel : Bool
        , config : Config
        }
