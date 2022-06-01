module Messages exposing (Msg(..), Question, LearnData, Model)

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
        | LoadLocalStorage

type alias Model =
        { page_state : Int
        , learnData : LearnData
        , learnProgress : LearnProgress
        , errorMessage : Maybe String
        }
