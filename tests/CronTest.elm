module CronTest exposing (..)

import Cron exposing (Atom(..), Cron(..), Expr(..), Month(..), Term(..), WeekDay(..))
import Expect exposing (Expectation, fail, pass)
import Parser exposing (DeadEnd, Problem(..))
import Test exposing (..)


sunshine : Test
sunshine =
    describe "sunshine"
        [ describe "numerical expressions"
            [ test "lots of spaces" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Single (Simple (Particle 0))) (Single (Simple (Particle 12))) (Single (Simple (Particle 1))) (Single (Simple (Particle January))) (Single (Simple (Particle Tuesday)))))
                        (Cron.fromString "    0   12    1 1 2   ")
            , test "zero prefixed" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Single (Simple (Particle 0))) (Single (Simple (Particle 12))) (Single (Simple (Particle 1))) (Single (Simple (Particle January))) (Single (Simple (Particle Tuesday)))))
                        (Cron.fromString "00 012 01 01 02")
            ]
        , describe "stars"
            [ test "all stars" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every Every))
                        (Cron.fromString "    *   * *   *  *  ")
            , test "combinations" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every (Single (Simple (Particle 1))) Every (Single (Simple (Particle January))) Every))
                        (Cron.fromString "    *   1 *   1  *  ")
            ]
        , describe "steps"
            [ test "every step" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (EveryStep 1))))
                        (Cron.fromString "* * * * */1")
            , test "every 1 step" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (Step (Particle Monday) 1))))
                        (Cron.fromString "* * * * 1/1")
            , test "every third step" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (EveryStep 3))))
                        (Cron.fromString "* * * * */3")
            , test "every third step on the 2nd" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (Step (Particle Tuesday) 3))))
                        (Cron.fromString "* * * * 2/3")
            , test "every third step on the second to fourth" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (Step (Range Tuesday Thursday) 3))))
                        (Cron.fromString "* * * * 2-4/3")
            ]
        , describe "ranges"
            [ test "single range" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Single (Simple (Range 1 2))) Every Every Every Every))
                        (Cron.fromString "1-2 * * * *")
            , test "all ranges" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Single (Simple (Range 1 2))) (Single (Simple (Range 1 2))) (Single (Simple (Range 1 2))) (Single (Simple (Range January February))) (Single (Simple (Range Monday Tuesday)))))
                        (Cron.fromString "1-2 1-2 1-2 1-2 1-2")
            , test "combinations" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every (Single (Simple (Range 2 5))) (Single (Simple (Range 1 2))) (Single (Simple (Particle January))) (Single (Simple (Range Monday Tuesday)))))
                        (Cron.fromString "* 2-5 1-2 1 1-2")
            ]
        , describe "sequences"
            [ test "sequence of literals" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Multiple [ Simple (Particle 1), Simple (Particle 2) ]) Every Every Every Every))
                        (Cron.fromString "1,2 * * * *")
            , test "sequence of ranges and literals" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Multiple [ Simple (Particle 1), Simple (Range 2 4) ]) Every Every Every Every))
                        (Cron.fromString "1,2-4 * * * *")
            , test "sequence of ranges, literals and steps" <|
                \() ->
                    Expect.equal
                        (Ok (Cron (Multiple [ Simple (Particle 1), Step (Range 2 4) 3 ]) Every Every Every Every))
                        (Cron.fromString "1,2-4/3 * * * *")
            ]
        , describe "ordinals"
            [ test "named week days" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (Simple (Particle Sunday)))))
                        (Cron.fromString "* * * * SUN")
            , test "named week days and steps" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every Every (Single (Step (Particle Wednesday) 2))))
                        (Cron.fromString "* * * * wed/2")
            , test "named months" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every (Single (Simple (Particle February))) Every))
                        (Cron.fromString "* *  *  FEB *")
            , test "named months in multiple ranges" <|
                \() ->
                    Expect.equal
                        (Ok (Cron Every Every Every (Multiple [ Simple (Range February May), Simple (Range July October) ]) Every))
                        (Cron.fromString "* * * FEB-may,jul-oct *")
            ]
        ]


rain : Test
rain =
    describe "rain"
        [ describe "out of range"
            [ test "minutes outside range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 0 through 59.")
                        (Cron.fromString "61 0 0 0 0")
            , test "hours outside range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 0 through 23.")
                        (Cron.fromString "0 25 0 0 0")
            , test "DOM outside range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 1 through 31.")
                        (Cron.fromString "0 0 32 0 0")
            , test "month outside range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 1 through 12.")
                        (Cron.fromString "0 0 1 13 0")
            , test "DOW outside range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 0 through 6.")
                        (Cron.fromString "0 0 3 1 10")
            ]
        , describe "ranges"
            [ test "out of range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 0 through 6.")
                        (Cron.fromString "* 2-5 1-2 1 7-8")
            , test "double range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected the name of a month (jan, feb, mar etc...) or a number from 1 through 12.")
                        (Cron.fromString "* * 1-2-3 * *")
            ]
        , describe "steps"
            [ test "every 0 step" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected the name of a week day (sun, mon, tue etc...) or a number from 0 through 6.")
                        (Cron.fromString "* * * 1/0 *")
            , test "Multiple steps" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected the name of a week day (sun, mon, tue etc...) or a number from 0 through 6.")
                        (Cron.fromString "* * * 1-2/1-3 *")
            , test "Multiple steps at the end" <|
                \() ->
                    expectFirstProblem
                        ExpectingEnd
                        (Cron.fromString "* * * * 1-2/1-3")
            ]
        , describe "sequences"
            [ test "out of range" <|
                \() ->
                    expectFirstProblem
                        (Problem "Expected an integer from 1 through 31.")
                        (Cron.fromString "1,2 * 30,31,32 * *")
            ]
        ]



-----------------------------------------------
-- Helpers
-----------------------------------------------


expectFirstProblem : Problem -> Result (List DeadEnd) Cron -> Expectation
expectFirstProblem problem result =
    case result of
        Ok cron ->
            fail ("Parsing was expected to fail with " ++ Debug.toString problem ++ " but it returned " ++ Debug.toString cron)

        Err (head :: _) ->
            Expect.equal head.problem problem

        Err [] ->
            fail "No problems returned"
