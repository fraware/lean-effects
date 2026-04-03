-- Specification and combination tests
import Effects
import Effects.Std.State
import Effects.Std.Exception
import Effects.Std.Reader
import Effects.Std.Writer
import Effects.Std.Nondet
import Effects.Compose.Sum
import Effects.Compose.Product
import Effects.Examples.SmallLang

namespace ProductionSpecTest

-- Test 1: State ⊕ Exception Handler Implementation
def testStateExceptionHandler : StateExceptionTest.StateException.Free Nat String Nat :=
  StateExceptionTest.StateException.get Nat String >>= fun current =>
    if current > 0 then
      StateExceptionTest.StateException.put Nat String (current + 1) >>= fun _ =>
        pure current
    else
      StateExceptionTest.StateException.throw Nat String "negative state" >>= fun _ =>
        pure current

-- Test 2: Reader × Writer Fusion Theorems
def testReaderWriterFusion : ReaderWriterTest.ReaderWriter.Free Nat Nat Nat :=
  ReaderWriterTest.ReaderWriter.ask Nat Nat >>= fun current =>
    ReaderWriterTest.ReaderWriter.tell Nat Nat current >>= fun _ =>
      pure current

-- Test 3: Small Language Interpreter
def testSmallLangInterpreter : Expr :=
  .add (.lit 1) (.add (.get) (.put (.lit 5)))

-- Test 4: Nondet Commutativity/Idempotence
def testNondetLaws : Nondet.Free Nat :=
  Nondet.choice (Nondet.choice 1 2) (Nondet.choice 3 4)

-- Test 5: State ⊕ Exception Laws
theorem stateExceptionLaws (s : Nat) :
  StateExceptionTest.StateExceptionT.run (testStateExceptionHandler s) s =
  if s > 0 then
    (.ok (s, s + 1))
  else
    (.error "negative state") := by
  simp [testStateExceptionHandler, StateExceptionTest.StateExceptionT.run,
        StateExceptionTest.StateException.get, StateExceptionTest.StateException.put,
        StateExceptionTest.StateException.throw, bind]

-- Test 6: Reader × Writer Laws
theorem readerWriterLaws (r : Nat) :
  ReaderWriterTest.ReaderWriterT.run (testReaderWriterFusion r) r = (r, r) := by
  simp [testReaderWriterFusion, ReaderWriterTest.ReaderWriterT.run,
        ReaderWriterTest.ReaderWriter.ask, ReaderWriterTest.ReaderWriter.tell, bind]

-- Test 7: Small Language Interpreter Laws
theorem smallLangLaws (s : Nat) :
  run testSmallLangInterpreter s = (.ok (6, 5, ["Value: 6"])) := by
  simp [testSmallLangInterpreter, run, interp, SmallLang.get, SmallLang.put, SmallLang.tell]

-- Test 8: Nondet Commutativity
theorem nondetCommutativity (x y : Nat) :
  Nondet.choice x y = Nondet.choice y x := by
  simp [Nondet.choice, List.append_comm]

-- Test 9: Nondet Idempotence
theorem nondetIdempotence (x : Nat) :
  Nondet.choice x x = x := by
  simp [Nondet.choice, List.append_nil]

-- Test 10: Nondet Associativity
theorem nondetAssociativity (x y z : Nat) :
  Nondet.choice (Nondet.choice x y) z = Nondet.choice x (Nondet.choice y z) := by
  simp [Nondet.choice, List.append_assoc]

-- Test 11: State ⊕ Exception Composition
def testStateExceptionComposition : StateExceptionTest.StateException.Free Nat String (Nat × Nat) :=
  StateExceptionTest.StateException.get Nat String >>= fun s1 =>
    StateExceptionTest.StateException.put Nat String (s1 + 1) >>= fun _ =>
      StateExceptionTest.StateException.get Nat String >>= fun s2 =>
        if s2 > 0 then
          pure (s1, s2)
        else
          StateExceptionTest.StateException.throw Nat String "invalid state" >>= fun _ =>
            pure (s1, s2)

-- Test 12: Reader × Writer Composition
def testReaderWriterComposition : ReaderWriterTest.ReaderWriter.Free Nat Nat (Nat × Nat) :=
  ReaderWriterTest.ReaderWriter.ask Nat Nat >>= fun r1 =>
    ReaderWriterTest.ReaderWriter.tell Nat Nat r1 >>= fun _ =>
      ReaderWriterTest.ReaderWriter.ask Nat Nat >>= fun r2 =>
        ReaderWriterTest.ReaderWriter.tell Nat Nat r2 >>= fun _ =>
          pure (r1, r2)

-- Test 13: Small Language Complex Expression
def testComplexExpression : Expr :=
  .catch (.add (.get) (.throw (.lit 42))) (.add (.lit 1) (.lit 2))

-- Test 14: Nondet Complex Choice
def testComplexNondet : Nondet.Free Nat :=
  Nondet.choice (Nondet.choice 1 2) (Nondet.choice (Nondet.choice 3 4) 5)

-- Test 15: All Effects Combined
def testAllEffectsCombined : StateExceptionTest.StateException.Free Nat String (ReaderWriterTest.ReaderWriter.Free Nat Nat Nat) :=
  StateExceptionTest.StateException.get Nat String >>= fun s =>
    if s > 0 then
      StateExceptionTest.StateException.put Nat String (s + 1) >>= fun _ =>
        pure (ReaderWriterTest.ReaderWriter.ask Nat Nat >>= fun r =>
          ReaderWriterTest.ReaderWriter.tell Nat Nat r >>= fun _ =>
            pure r)
    else
      StateExceptionTest.StateException.throw Nat String "negative state" >>= fun _ =>
        pure (ReaderWriterTest.ReaderWriter.ask Nat Nat >>= fun r =>
          ReaderWriterTest.ReaderWriter.tell Nat Nat r >>= fun _ =>
            pure r)

end ProductionSpecTest
