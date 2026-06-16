-- README minimal State example (stable `import Effects` only)
import Effects

open Effects.Std

def stateExample : State.Free Nat Nat := do
  let current ← State.get Nat
  State.put Nat (current + 1)
  State.get Nat

#eval State.run stateExample 0   -- (1, 1)
