-- Handler laws tactics
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.Fusion
import Effects.Tactics.EffectFuse
import Lean
import Lean.Elab.Tactic

namespace Effects.Tactics

-- Local simplification tactic with bounded search
elab "local_simp!" : tactic => do
  let goal ← Lean.Elab.Tactic.getMainGoal
  let goalType ← Lean.Elab.Tactic.getGoalType goal

  -- Define bounded search with fixed order of simplification tactics
  let simplificationTactics : List Syntax := [
    ← `(tactic| simp),
    ← `(tactic| simp [Effects.Core.FreeMonad.pure_bind]),
    ← `(tactic| simp [Effects.Core.FreeMonad.bind_pure]),
    ← `(tactic| simp [Effects.Core.FreeMonad.bind_assoc]),
    ← `(tactic| simp [Effects.Core.FreeMonad.map_id]),
    ← `(tactic| simp [Effects.Core.FreeMonad.map_comp]),
    ← `(tactic| simp [Effects.Core.Handler.interpret_pure]),
    ← `(tactic| simp [Effects.Core.Handler.interpret_bind]),
    ← `(tactic| simp [Effects.Core.Handler.interpret_map])
  ]

  -- Try simplification tactics in fixed order (bounded search)
  let mut found := false
  for tactic in simplificationTactics do
    try
      Lean.Elab.Tactic.evalTactic tactic
      found := true
      break
    catch _ =>
      continue

  -- If nothing worked, provide specific error message
  if !found then
    Lean.Elab.Tactic.throwError "No applicable simplification found. Goal type: {goalType}. Consider using manual simplification or check if the goal is in the correct form."

end Effects.Tactics
