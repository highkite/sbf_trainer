module QuestionSelectionLogic exposing (takeNextQuestion, mergeModel, getDueQuestions)
import Date exposing (Unit(..), add, fromIsoString, compare)

import List exposing (head, tail, take, drop, range, length, isEmpty)

import Messages exposing (LearnProgress, QuestionLearnProgress, CurQuest, Model, Question, AnswerState(..), LearnData, Id)

takeNextQuestion : Model -> LearnProgress -> Int -> Maybe CurQuest
takeNextQuestion model lp index =
    case (takeDue model (Just (List.drop index lp)) index) of
        Just aSet ->
            case lookupQuestion (Just model.learnData) (Just aSet.question) of
                Just quest ->
                    let
                        rands = range 0 ((length quest.answers) - 1)
                    in
                    Just {index = aSet.index, progress = aSet.question, question = quest, randomization = rands, correct = NotSet}
                Nothing ->
                    Nothing
        Nothing ->
            case (takeDue model (Just (take (index - 1) lp)) index) of
                Just bSet ->
                    case lookupQuestion (Just model.learnData) (Just bSet.question) of
                        Just quest ->
                            let
                                rands = range 0 ((length quest.answers) - 1)
                            in
                            Just {index = bSet.index, progress = bSet.question, question = quest, randomization = rands, correct = NotSet}
                        Nothing ->
                            Nothing
                Nothing ->
                    case (getElement (Just lp) index) of
                        Just element ->
                            if isDue model element then
                                case lookupQuestion (Just model.learnData) (Just element) of
                                    Just quest ->
                                        let
                                            rands = range 0 ((length quest.answers) - 1)
                                        in
                                        Just {index = index, progress = element, question = quest, randomization = rands, correct = NotSet}
                                    Nothing ->
                                        Nothing
                            else
                                Nothing
                        Nothing ->
                            Nothing

takeDue : Model -> Maybe LearnProgress -> Int -> Maybe { question : QuestionLearnProgress, index : Int }
takeDue model lp index =
    case lp of
        Just lplst ->
            case head lplst of
                Just headel ->
                    if isDue model headel then
                        Just {question = headel, index = index}
                    else
                        takeDue model (tail lplst) (index + 1)

                Nothing ->
                    Nothing

        Nothing ->
            Nothing

lookupQuestion : Maybe LearnData -> Maybe QuestionLearnProgress -> Maybe Question
lookupQuestion ld lp =
        case lp of
                Just lpl ->
                        case ld of
                                Just ldl ->
                                        case head ldl of
                                                Just headel ->
                                                        if headel.ide == lpl.ide then
                                                                Just headel
                                                        else
                                                                lookupQuestion (tail ldl) lp
                                                Nothing ->
                                                        Nothing

                                Nothing ->
                                        Nothing
                Nothing ->
                        Nothing

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

getDueQuestions : Model -> Maybe LearnProgress -> LearnProgress
getDueQuestions model lp =
    case lp of
        Just lp_lst ->
            case head lp_lst of
                Just headel ->
                    if isDue model headel then
                        headel :: getDueQuestions model (tail lp_lst)
                    else
                        getDueQuestions model (tail lp_lst)
                Nothing ->
                    []
        Nothing ->
            []

isDue : Model -> QuestionLearnProgress -> Bool
isDue model lp =
        case lp.level of
                0 ->
                        True
                1 ->
                        phaseOneDue model.currentDate lp.timestamp
                2 ->
                        phaseTwoDue model.currentDate lp.timestamp
                3 ->
                        phaseThreeDue model.currentDate lp.timestamp
                4 ->
                        phaseFourDue model.currentDate lp.timestamp
                5 ->
                        phaseFiveDue model.currentDate lp.timestamp
                _ ->
                        False

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

mergeModel :  Model -> Maybe LearnData -> Model
mergeModel model ld =
    case ld of
        Just ldl ->
            case head ldl of
                Just headel ->
                    if (isIn (Just model.learnProgress) headel.ide) then
                        mergeModel model (tail ldl)
                    else
                        mergeModel { model | learnProgress = ({ide = headel.ide, level = 0, timestamp = model.currentDate} :: model.learnProgress) } (tail ldl)
                Nothing ->
                    model
        Nothing ->
            model

isIn : Maybe LearnProgress -> Id -> Bool
isIn lp id =
    case lp of
        Just lplst ->
            case head lplst of
                Just headel ->
                    if isEqual headel.ide id then
                        True
                    else
                        isIn (tail lplst) id
                Nothing ->
                    False
        Nothing ->
            False

isEqual : Id -> Id -> Bool
isEqual one two =
    one.ide == two.ide && one.questionType == two.questionType

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


-- Create learn progress if it does not yet exists
populateModel : Model -> Model
populateModel model =
        case isEmpty(model.learnProgress) of
                True ->
                        createQuestionLearnProgress (Just model.learnData) model
                False ->
                        model
