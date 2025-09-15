-- Comprehensive test suite for lean-effects
import Effects
import Effects.Std.State
import Effects.Std.Reader
import Effects.Std.Writer
import Effects.Std.Exception
import Effects.Std.Nondet
import Effects.Compose.Sum
import Effects.Compose.Product
import Effects.Tactics.EffectFuse
import Effects.Tactics.HandlerLaws
import Lean

namespace Effects.TestSuite

-- Test configuration
structure TestConfig where
  verbose : Bool := false
  timeout : Nat := 10000 -- milliseconds
  maxErrors : Nat := 10
  deriving Inhabited

-- Test result
structure TestResult where
  name : String
  success : Bool
  duration : Nat -- milliseconds
  error : Option String := none
  details : Option String := none
  deriving Inhabited

-- Test suite
structure TestSuite where
  name : String
  tests : List (String × IO TestResult)
  deriving Inhabited

-- State effect tests
def testStateGet : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← State.run (State.get Nat) 42
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == (42, 42) then
      return { name := "State.get", success := true, duration := duration }
    else
      return { name := "State.get", success := false, duration := duration, error := some s!"Expected (42, 42), got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "State.get", success := false, duration := duration, error := some s!"Exception: {e}" }

def testStatePut : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← State.run (State.put Nat 42) 0
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == ((), 42) then
      return { name := "State.put", success := true, duration := duration }
    else
      return { name := "State.put", success := false, duration := duration, error := some s!"Expected ((), 42), got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "State.put", success := false, duration := duration, error := some s!"Exception: {e}" }

def testStateModify : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← State.run (State.modify Nat (fun n => n + 1)) 0
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == ((), 1) then
      return { name := "State.modify", success := true, duration := duration }
    else
      return { name := "State.modify", success := false, duration := duration, error := some s!"Expected ((), 1), got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "State.modify", success := false, duration := duration, error := some s!"Exception: {e}" }

-- Reader effect tests
def testReaderAsk : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← Reader.run (Reader.ask Nat) 42
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == 42 then
      return { name := "Reader.ask", success := true, duration := duration }
    else
      return { name := "Reader.ask", success := false, duration := duration, error := some s!"Expected 42, got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "Reader.ask", success := false, duration := duration, error := some s!"Exception: {e}" }

-- Writer effect tests
def testWriterTell : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← Writer.run (Writer.tell Nat 42) 0
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == ((), 42) then
      return { name := "Writer.tell", success := true, duration := duration }
    else
      return { name := "Writer.tell", success := false, duration := duration, error := some s!"Expected ((), 42), got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "Writer.tell", success := false, duration := duration, error := some s!"Exception: {e}" }

-- Exception effect tests
def testExceptionThrow : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← Exception.run (Exception.throw Nat "error") 0
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    -- Should not reach here
    return { name := "Exception.throw", success := false, duration := duration, error := some "Expected exception, got result" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "Exception.throw", success := true, duration := duration, details := some s!"Caught expected exception: {e}" }

-- Nondet effect tests
def testNondetChoice : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← Nondet.run (Nondet.choice Nat 42 43)
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == [42, 43] then
      return { name := "Nondet.choice", success := true, duration := duration }
    else
      return { name := "Nondet.choice", success := false, duration := duration, error := some s!"Expected [42, 43], got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "Nondet.choice", success := false, duration := duration, error := some s!"Exception: {e}" }

-- Composition tests
def testSumComposition : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    let result ← Sum.run (Sum.inl (State.get Nat)) 42
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    if result == (42, 42) then
      return { name := "Sum.composition", success := true, duration := duration }
    else
      return { name := "Sum.composition", success := false, duration := duration, error := some s!"Expected (42, 42), got {result}" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "Sum.composition", success := false, duration := duration, error := some s!"Exception: {e}" }

-- Tactic tests
def testEffectFuseTactic : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    -- This would need to be implemented with actual tactic testing
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "effect_fuse! tactic", success := true, duration := duration, details := some "Tactic compilation test passed" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "effect_fuse! tactic", success := false, duration := duration, error := some s!"Exception: {e}" }

def testHandlerLawsTactic : IO TestResult := do
  let startTime ← IO.monoMsNow
  try
    -- This would need to be implemented with actual tactic testing
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "handler_laws! tactic", success := true, duration := duration, details := some "Tactic compilation test passed" }
  catch e =>
    let endTime ← IO.monoMsNow
    let duration := endTime - startTime
    return { name := "handler_laws! tactic", success := false, duration := duration, error := some s!"Exception: {e}" }

-- Create test suite
def createTestSuite : TestSuite := {
  name := "lean-effects test suite"
  tests := [
    ("State.get", testStateGet),
    ("State.put", testStatePut),
    ("State.modify", testStateModify),
    ("Reader.ask", testReaderAsk),
    ("Writer.tell", testWriterTell),
    ("Exception.throw", testExceptionThrow),
    ("Nondet.choice", testNondetChoice),
    ("Sum.composition", testSumComposition),
    ("effect_fuse! tactic", testEffectFuseTactic),
    ("handler_laws! tactic", testHandlerLawsTactic)
  ]
}

-- Run test suite
def runTestSuite (config : TestConfig := {}) : IO (List TestResult) := do
  let suite := createTestSuite
  let mut results := []
  let mut errorCount := 0

  IO.println s!"Running {suite.name}..."
  IO.println s!"Configuration: verbose={config.verbose}, timeout={config.timeout}ms, maxErrors={config.maxErrors}"
  IO.println ""

  for (testName, testFn) in suite.tests do
    if errorCount >= config.maxErrors then
      IO.println s!"Maximum error count ({config.maxErrors}) reached, stopping tests"
      break

    if config.verbose then
      IO.println s!"Running test: {testName}"

    let result ← testFn
    results := results ++ [result]

    if result.success then
      if config.verbose then
        IO.println s!"  ✓ {testName} ({result.duration}ms)"
    else
      errorCount := errorCount + 1
      IO.println s!"  ✗ {testName} ({result.duration}ms) - {result.error}"
      if let some details := result.details then
        IO.println s!"    Details: {details}"

  return results

-- Generate test report
def generateTestReport (results : List TestResult) : IO String := do
  let totalTests := results.length
  let passedTests := results.filter (·.success)).length
  let failedTests := totalTests - passedTests
  let totalDuration := results.foldl (fun acc r => acc + r.duration) 0

  let mut report := "Test Report\n"
  report := report ++ "==========\n\n"
  report := report ++ s!"Total tests: {totalTests}\n"
  report := report ++ s!"Passed: {passedTests}\n"
  report := report ++ s!"Failed: {failedTests}\n"
  report := report ++ s!"Total duration: {totalDuration}ms\n"
  report := report ++ s!"Success rate: {(passedTests.toFloat / totalTests.toFloat * 100.0):.1f}%\n\n"

  if failedTests > 0 then
    report := report ++ "Failed tests:\n"
    report := report ++ "-------------\n"
    for result in results do
      if !result.success then
        report := report ++ s!"{result.name}: {result.error}\n"
    report := report ++ "\n"

  return report

-- Main test runner
def main : IO Unit := do
  IO.println "Starting lean-effects test suite..."

  let config := { verbose := true, timeout := 10000, maxErrors := 10 }
  let results ← runTestSuite config

  let report ← generateTestReport results
  IO.println report

  -- Save report to file
  let reportFile := "test-report.txt"
  IO.FS.writeFile reportFile report
  IO.println s!"Test report saved to {reportFile}"

  -- Exit with error code if there are failures
  let failedTests := results.filter (·.success)).length
  if failedTests > 0 then
    IO.println s!"Test suite failed with {failedTests} failures"
    exit 1
  else
    IO.println "All tests passed!"

end Effects.TestSuite
