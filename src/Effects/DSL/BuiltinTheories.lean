-- Lawvere-theory metadata for standard and composed effects (DSL layer only)
import Effects.DSL.Syntax
import Effects.Std.State
import Effects.Std.Reader
import Effects.Std.Writer
import Effects.Std.Exception
import Effects.Std.Nondet
import Effects.Compose.Sum
import Effects.Compose.Product

namespace Effects.DSL

open Effects.Std (StateSig ReaderSig WriterSig ExceptionSig)

def StateTheory (σ : Type u) : Theory where
  name := "State"
  params := [⟨"σ", "Type u"⟩]
  ops := [
    ⟨"get", Ty.unit, Ty.param "σ"⟩,
    ⟨"put", Ty.param "σ", Ty.unit⟩
  ]
  eqns := [
    ⟨"put_get",
     Term.op "put" [Term.var "s"] ∘ Term.op "get" [Term.unit],
     Term.var "s"⟩
  ]

def ReaderTheory (ρ : Type u) : Theory where
  name := "Reader"
  params := [⟨"ρ", "Type u"⟩]
  ops := [
    ⟨"ask", Ty.unit, Ty.param "ρ"⟩
  ]
  eqns := []

def WriterTheory (ω : Type u) [Monoid ω] : Theory where
  name := "Writer"
  params := [⟨"ω", "Type u"⟩]
  ops := [
    ⟨"tell", Ty.param "ω", Ty.unit⟩
  ]
  eqns := []

def ExceptionTheory (ε : Type u) : Theory where
  name := "Exception"
  params := [⟨"ε", "Type u"⟩]
  ops := [
    ⟨"throw", Ty.param "ε", Ty.unit⟩
  ]
  eqns := []

def NondetTheory : Theory where
  name := "Nondet"
  params := []
  ops := [
    ⟨"empty", Ty.unit, Ty.unit⟩,
    ⟨"choice", Ty.prod Ty.unit Ty.unit, Ty.unit⟩
  ]
  eqns := [
    ⟨"assoc", Term.op "choice" [Term.pair (Term.op "choice" [Term.pair (Term.var "x") (Term.var "y")]) (Term.var "z")],
     Term.op "choice" [Term.pair (Term.var "x") (Term.op "choice" [Term.pair (Term.var "y") (Term.var "z")])]⟩,
    ⟨"comm", Term.op "choice" [Term.pair (Term.var "x") (Term.var "y")],
     Term.op "choice" [Term.pair (Term.var "y") (Term.var "x")]⟩,
    ⟨"idemp", Term.op "choice" [Term.pair (Term.var "x") (Term.var "x")], Term.var "x"⟩
  ]

def SumTheory (F G : Type u → Type u) [Functor F] [Functor G] : Theory where
  name := "Sum"
  params := []
  ops := [
    ⟨"inl", Ty.unit, Ty.unit⟩,
    ⟨"inr", Ty.unit, Ty.unit⟩
  ]
  eqns := []

def ProductTheory (F G : Type u → Type u) [Functor F] [Functor G] : Theory where
  name := "Product"
  params := []
  ops := [
    ⟨"mk", Ty.prod Ty.unit Ty.unit, Ty.unit⟩
  ]
  eqns := []

-- Composition aliases for the DSL
def State ⊗ Exception := SumTheory StateSig ExceptionSig
def Reader × Writer := ProductTheory ReaderSig WriterSig

end Effects.DSL
