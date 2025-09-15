-- Effect fusion tactics
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.Fusion
import Lean
import Lean.Elab.Tactic

namespace Effects.Tactics

-- Effect fusion tactic with bounded search
elab "effect_fuse!" : tactic => do
  let goal ← Lean.Elab.Tactic.getMainGoal
  let goalType ← Lean.Elab.Tactic.getGoalType goal

  -- Define bounded search with fixed order of theorems
  let fusionTheorems : List Syntax := [
    ← `(Effects.Core.FreeMonad.fold_fusion_basic),
    ← `(Effects.Core.FreeMonad.fold_map_fusion),
    ← `(Effects.Core.FreeMonad.fold_bind_fusion),
    ← `(Effects.Core.FreeMonad.fold_handler_fusion),
    ← `(Effects.Core.FreeMonad.fold_effect_fusion),
    ← `(Effects.Core.FreeMonad.fold_state_fusion),
    ← `(Effects.Core.FreeMonad.fold_exception_fusion),
    ← `(Effects.Core.FreeMonad.fold_reader_fusion),
    ← `(Effects.Core.FreeMonad.fold_writer_fusion),
    ← `(Effects.Core.FreeMonad.fold_nondet_fusion)
  ]

  let simplificationTactics : List Syntax := [
    ← `(tactic| simp),
    ← `(tactic| simp [Effects.Core.FreeMonad.pure_bind]),
    ← `(tactic| simp [Effects.Core.FreeMonad.bind_pure]),
    ← `(tactic| simp [Effects.Core.FreeMonad.bind_assoc]),
    ← `(tactic| simp [Effects.Core.FreeMonad.map_id]),
    ← `(tactic| simp [Effects.Core.FreeMonad.map_comp])
  ]

  -- Try fusion theorems in fixed order (bounded search)
  let mut found := false
  for theorem in fusionTheorems do
    try
      Lean.Elab.Tactic.evalTactic (← `(tactic| apply $theorem))
      found := true
      break
    catch _ =>
      continue

  -- If no fusion theorem worked, try simplification tactics
  if !found then
    for tactic in simplificationTactics do
      try
        Lean.Elab.Tactic.evalTactic tactic
        found := true
        break
      catch _ =>
        continue

  -- If nothing worked, provide specific error message
  if !found then
    Lean.Elab.Tactic.throwError "No applicable fusion theorem or simplification found. Goal type: {goalType}. Consider using manual fusion or check if the goal is in the correct form."

-- Handler laws tactic with bounded search
elab "handler_laws!" : tactic => do
  let goal ← Lean.Elab.Tactic.getMainGoal
  let goalType ← Lean.Elab.Tactic.getGoalType goal

  -- Define bounded search with fixed order of handler laws
  let handlerLaws : List Syntax := [
    ← `(Effects.Core.Handler.interpret_pure),
    ← `(Effects.Core.Handler.interpret_bind),
    ← `(Effects.Core.Handler.interpret_map),
    ← `(Effects.Core.Handler.interpret_pure_bind),
    ← `(Effects.Core.Handler.interpret_bind_pure),
    ← `(Effects.Core.Handler.interpret_bind_assoc)
  ]

  let simplificationTactics : List Syntax := [
    ← `(tactic| simp),
    ← `(tactic| simp [Effects.Core.Handler.interpret_pure]),
    ← `(tactic| simp [Effects.Core.Handler.interpret_bind]),
    ← `(tactic| simp [Effects.Core.Handler.interpret_map]),
    ← `(tactic| simp [Effects.Core.FreeMonad.pure_bind]),
    ← `(tactic| simp [Effects.Core.FreeMonad.bind_pure]),
    ← `(tactic| simp [Effects.Core.FreeMonad.bind_assoc])
  ]

  -- Try handler laws in fixed order (bounded search)
  let mut found := false
  for law in handlerLaws do
    try
      Lean.Elab.Tactic.evalTactic (← `(tactic| apply $law))
      found := true
      break
    catch _ =>
      continue

  -- If no handler law worked, try simplification tactics
  if !found then
    for tactic in simplificationTactics do
      try
        Lean.Elab.Tactic.evalTactic tactic
        found := true
        break
      catch _ =>
        continue

  -- If nothing worked, provide specific error message
  if !found then
    Lean.Elab.Tactic.throwError "No applicable handler law or simplification found. Goal type: {goalType}. Consider using manual application or check if the goal is in the correct form."

end Effects.Tactics
