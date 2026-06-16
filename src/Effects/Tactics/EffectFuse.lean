-- Effect fusion tactics (repository-local; not part of stable CSLib core)
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.Fusion

namespace Effects.Tactics

macro "effect_fuse!" : tactic =>
  `(tactic| first
    | apply Effects.Core.FreeMonad.fold_fusion_basic
    | simp [Effects.Core.FreeMonad.bind_pure_simp]
    | simp [Effects.Core.FreeMonad.bind_pure_eta]
    | simp [Effects.Core.FreeMonad.bind_assoc_simp]
    | simp [Effects.Core.FreeMonad.map_id]
    | simp [Effects.Core.FreeMonad.map_comp])

macro "handler_laws!" : tactic =>
  `(tactic| first
    | simp [Effects.Core.Handler.interpret_pure]
    | simp [Effects.Core.Handler.interpret_bind]
    | simp [Effects.Core.FreeMonad.bind_pure_simp]
    | simp [Effects.Core.FreeMonad.bind_pure_eta]
    | simp [Effects.Core.FreeMonad.bind_assoc_simp])

end Effects.Tactics
