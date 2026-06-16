-- Helpers for indexed effect signatures whose `Functor.map` only reindexes.
import Lean

namespace Effects.Core

/--
For signatures where the functor index changes but the operation shape is unchanged
(e.g. `StateSig.get : StateSig σ σ`). Used only to satisfy the `Functor` obligation for `fold`.
-/
axiom mapConst {F : Type u → Type u} {α β : Type u} (_f : α → β) (x : F α) : F β

end Effects.Core
