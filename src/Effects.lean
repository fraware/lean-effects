-- Main Effects module
import Effects.DSL.Syntax
import Effects.DSL.Elab
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.Fusion
import Effects.Std.State
import Effects.Std.Reader
import Effects.Std.Writer
import Effects.Std.Exception
import Effects.Std.Nondet
import Effects.Compose.Sum
import Effects.Compose.Product
import Effects.Tactics.EffectFuse
import Effects.Tactics.HandlerLaws

-- Export DSL functionality
export Effects.DSL (Theory Op Eqn Param Ty Term)
export Effects.DSL (findOp findEqn hasOp hasEqn isWellFormed)
export Effects.DSL (ppTheory ppTy ppOp ppEqn)

-- Export core functionality
export Effects.Core (FreeMonad)
export Effects.Core (Handler interpret interpret_pure interpret_bind)
export Effects.Core (buildHandler liftSumHandler liftProductHandler)

-- Export standard library
export Effects.Std.State (State State.Free get put modify modifyGet gets run eval exec)
export Effects.Std.Reader (Reader Reader.Free ask run local)
export Effects.Std.Writer (Writer Writer.Free tell run eval exec)
export Effects.Std.Exception (Exception Exception.Free throw run catch)
export Effects.Std.Nondet (Nondet Nondet.Free empty choice run toList first)

-- Export composition
export Effects.Compose.Sum (Sum Sum.Free inl inr handler)
export Effects.Compose.Product (Product Product.Free mk handler)

-- Export tactics
export Effects.Tactics (effect_fuse! handler_laws! local_simp!)

-- Export theory definitions
export Effects.Std.State (StateTheory)
export Effects.Std.Reader (ReaderTheory)
export Effects.Std.Writer (WriterTheory)
export Effects.Std.Exception (ExceptionTheory)
export Effects.Std.Nondet (NondetTheory)
export Effects.Compose.Sum (SumTheory)
export Effects.Compose.Product (ProductTheory)
