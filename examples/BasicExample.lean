-- Basic example of using the lean-effects library
import Effects

-- Define a simple state effect
theory Counter where
  op increment : Unit ⟶ Unit
  op get : Unit ⟶ Nat
end

-- Derive the effect
derive_effect Counter [free, handler, fusion, simp]

-- Use the effect
def counterExample : Counter.Free Nat :=
  Counter.increment >>= fun _ =>
  Counter.increment >>= fun _ =>
  Counter.get

-- Test the effect
theorem testCounter :
  Counter.run counterExample = 2 := by
  simp [counterExample, Counter.run, Counter.increment, Counter.get]

-- Define a simple exception effect
theory Error where
  op fail : String ⟶ Unit
end

-- Derive the effect
derive_effect Error [free, handler, fusion, simp]

-- Use the effect
def errorExample : Error.Free Nat :=
  Error.fail "something went wrong" >>= fun _ =>
  pure 42

-- Test the effect
theorem testError :
  Error.run errorExample = .error "something went wrong" := by
  simp [errorExample, Error.run, Error.fail]

-- Define a simple reader effect
theory Config where
  op read : Unit ⟶ String
end

-- Derive the effect
derive_effect Config [free, handler, fusion, simp]

-- Use the effect
def configExample : Config.Free String :=
  Config.read >>= fun config =>
  pure ("Config: " ++ config)

-- Test the effect
theorem testConfig (config : String) :
  Config.run configExample config = "Config: " ++ config := by
  simp [configExample, Config.run, Config.read]

-- Define a simple writer effect
theory Logger where
  op log : String ⟶ Unit
end

-- Derive the effect
derive_effect Logger [free, handler, fusion, simp]

-- Use the effect
def loggerExample : Logger.Free Nat :=
  Logger.log "Starting computation" >>= fun _ =>
  pure 42 >>= fun x =>
  Logger.log ("Result: " ++ toString x) >>= fun _ =>
  pure x

-- Test the effect
theorem testLogger :
  Logger.run loggerExample = (42, ["Starting computation", "Result: 42"]) := by
  simp [loggerExample, Logger.run, Logger.log]

-- Define a simple nondet effect
theory Choice where
  op choose : Nat ⟶ Nat
end

-- Derive the effect
derive_effect Choice [free, handler, fusion, simp]

-- Use the effect
def choiceExample : Choice.Free Nat :=
  Choice.choose 1 2 >>= fun x =>
  Choice.choose x 3 >>= fun y =>
  pure y

-- Test the effect
theorem testChoice :
  Choice.run choiceExample = [1, 2, 3] := by
  simp [choiceExample, Choice.run, Choice.choose]
