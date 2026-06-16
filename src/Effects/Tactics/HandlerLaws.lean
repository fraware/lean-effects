-- Handler laws tactics (repository-local; not part of stable CSLib core)
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Tactics.EffectFuse

namespace Effects.Tactics

macro "local_simp!" : tactic =>
  `(tactic| first
    | simp
    | simp [Effects.Core.FreeMonad.bind_pure_simp]
    | simp [Effects.Core.FreeMonad.bind_pure_eta]
    | simp [Effects.Core.FreeMonad.bind_assoc_simp]
    | simp [Effects.Core.FreeMonad.map_id]
    | simp [Effects.Core.FreeMonad.map_comp]
    | simp [Effects.Core.Handler.interpret_pure]
    | simp [Effects.Core.Handler.interpret_bind])

end Effects.Tactics
