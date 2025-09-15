-- Fusion tests
import Effects

namespace FusionTest

-- Test fusion theorems
theorem testFusion [Monad M] [Monad N] [Handler (StateSig Nat) M] [Handler (StateSig Nat) N]
  (h : M α → N α) (m : State.Free Nat α) :
  h (interpret m) = interpret (h <$> m) := by
  simp [interpret, Handler.interpret_pure, Handler.interpret_bind]

-- Test effect fusion
theorem testEffectFusion [Monad M] [Handler (StateSig Nat) M] (m : State.Free Nat α) :
  interpret (f <$> m) = f <$> interpret m := by
  simp [interpret, Handler.interpret_pure, Handler.interpret_bind]

end FusionTest
