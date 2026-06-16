-- Specification smoke tests (combo integration tests deferred to a later sprint)
import Effects

open Effects.Std

namespace ProductionSpecTest

def stateSmoke : State.Free Nat Nat := do
  let n ← State.get Nat
  State.put Nat (n + 1)
  State.get Nat

theorem stateSmokeEval : State.run stateSmoke 0 = (1, 1) := by
  native_decide

end ProductionSpecTest
