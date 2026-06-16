-- Comprehensive test suite for lean-effects
import Effects

namespace Effects.TestRunner

open Effects.Std

structure TestConfig where
  verbose : Bool := false
  timeout : Nat := 10000
  maxErrors : Nat := 10
  deriving Inhabited

structure TestResult where
  name : String
  success : Bool
  duration : Nat
  error : Option String := none
  details : Option String := none
  deriving Inhabited

structure Suite where
  name : String
  tests : List (String × IO TestResult)
  deriving Inhabited

def fail (name : String) (elapsed : Nat) (msg : String) : TestResult :=
  { name := name, success := false, duration := elapsed, error := some msg }

def pass (name : String) (elapsed : Nat) : TestResult :=
  { name := name, success := true, duration := elapsed }

def testStateGet : IO TestResult := do
  let t0 ← IO.monoMsNow
  let result := State.run (State.get Nat) 42
  let elapsed := (← IO.monoMsNow) - t0
  if result == (42, 42) then return pass "State.get" elapsed
  else return fail "State.get" elapsed "unexpected state get result"

def testStatePut : IO TestResult := do
  let t0 ← IO.monoMsNow
  let result := State.run (State.put Nat 42) 0
  let elapsed := (← IO.monoMsNow) - t0
  if result == (PUnit.unit, 42) then return pass "State.put" elapsed
  else return fail "State.put" elapsed "unexpected state put result"

def testReaderAsk : IO TestResult := do
  let t0 ← IO.monoMsNow
  let result := Reader.run (Reader.ask Nat) 42
  let elapsed := (← IO.monoMsNow) - t0
  if result == 42 then return pass "Reader.ask" elapsed
  else return fail "Reader.ask" elapsed "unexpected reader ask result"

def testExceptionThrow : IO TestResult := do
  let t0 ← IO.monoMsNow
  let r := Exception.run (Exception.throw (α := Nat) String "error")
  let elapsed := (← IO.monoMsNow) - t0
  match r with
  | .error "error" => return pass "Exception.throw" elapsed
  | _ => return fail "Exception.throw" elapsed "unexpected exception result"

def testNondetChoice : IO TestResult := do
  let t0 ← IO.monoMsNow
  let result := Nondet.run (Nondet.choice 42 43)
  let elapsed := (← IO.monoMsNow) - t0
  if result == [42, 43] then return pass "Nondet.choice" elapsed
  else return fail "Nondet.choice" elapsed "unexpected nondet choice result"

def createSuite : Suite := {
  name := "lean-effects test suite"
  tests := [
    ("State.get", testStateGet),
    ("State.put", testStatePut),
    ("Reader.ask", testReaderAsk),
    ("Exception.throw", testExceptionThrow),
    ("Nondet.choice", testNondetChoice)
  ]
}

def runSuite (config : TestConfig := {}) : IO (List TestResult) := do
  let suite := createSuite
  let mut results := []
  let mut errorCount := 0
  IO.println s!"Running {suite.name}..."
  for (testName, testFn) in suite.tests do
    if errorCount >= config.maxErrors then break
    if config.verbose then IO.println s!"Running test: {testName}"
    let result ← testFn
    results := results ++ [result]
    if result.success then
      if config.verbose then IO.println s!"  ok {testName} ({result.duration}ms)"
    else
      errorCount := errorCount + 1
      IO.println s!"  fail {testName} ({result.duration}ms) - {result.error}"
  return results

def generateReport (results : List TestResult) : IO String := do
  let totalTests := results.length
  let passedTests := (results.filter (·.success)).length
  let failedTests := totalTests - passedTests
  let totalDuration := results.foldl (fun acc r => acc + r.duration) 0
  let rate := if totalTests == 0 then 0 else passedTests * 100 / totalTests
  return "Test Report\n==========\n\n"
    ++ s!"Total tests: {totalTests}\n"
    ++ s!"Passed: {passedTests}\n"
    ++ s!"Failed: {failedTests}\n"
    ++ s!"Total duration: {totalDuration}ms\n"
    ++ s!"Success rate: {rate}%\n\n"

def runCli : IO Unit := do
  IO.println "Starting lean-effects test suite..."
  let config := { verbose := true, timeout := 10000, maxErrors := 10 }
  let results ← runSuite config
  let report ← generateReport results
  IO.println report
  IO.FS.writeFile "test-report.txt" report
  let failed := (results.filter (fun r => !r.success)).length
  if failed > 0 then
    IO.println s!"Test suite failed with {failed} failures"
    IO.Process.exit 1
  else
    IO.println "All tests passed!"

end Effects.TestRunner

def main : IO Unit := Effects.TestRunner.runCli
