-- Handler tests
import Effects

namespace HandlerTest

-- Test handler laws
theorem testHandlerPure [Monad M] [Handler (StateSig Nat) M] (x : α) :
  interpret (pure x : State.Free Nat α) = pure x := by
  simp [Handler.interpret_pure]

theorem testHandlerBind [Monad M] [Handler (StateSig Nat) M] (m : State.Free Nat α) (f : α → State.Free Nat β) :
  interpret (bind m f) = bind (interpret m) (fun x => interpret (f x)) := by
  simp [Handler.interpret_bind]

-- Test handler composition
theorem testHandlerComposition [Monad M] [Handler (StateSig Nat) M] (m : State.Free Nat α) :
  interpret (f <$> m) = f <$> interpret m := by
  simp [Handler.interpret_map]

end HandlerTest
