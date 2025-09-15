-- DSL syntax for Lawvere theories of effects
import Lean
import Mathlib.Data.List.Basic
import Mathlib.Data.String.Basic

namespace Effects.DSL

-- Type system for the DSL - supports Unit, finite products, finite sums, and parameters
inductive Ty where
  | unit : Ty
  | param (name : String) : Ty
  | prod (l r : Ty) : Ty
  | sum (l r : Ty) : Ty
  deriving BEq, Inhabited, Repr

-- Terms in the initial algebra - variables, operations, products, sums, composition
inductive Term where
  | var (name : String) : Term
  | unit : Term
  | pair (l r : Term) : Term
  | inl (t : Term) : Term
  | inr (t : Term) : Term
  | op (name : String) (args : List Term) : Term
  | comp (f g : Term) : Term
  | proj1 (t : Term) : Term
  | proj2 (t : Term) : Term
  | case (t : Term) (l : Term) (r : Term) : Term
  deriving BEq, Inhabited, Repr

-- Well-formedness checks for types
def Ty.isValid : Ty → Bool
  | .unit => true
  | .param name => name != ""
  | .prod l r => l.isValid && r.isValid
  | .sum l r => l.isValid && r.isValid

-- Operation definition - operations with domain and codomain types
structure Op where
  name : String
  dom : Ty
  cod : Ty
  deriving BEq, Inhabited, Repr

-- Equation definition - equational laws between terms
structure Eqn where
  name : String
  left : Term
  right : Term
  deriving BEq, Inhabited, Repr

-- Parameter definition - type parameters for theories
structure Param where
  name : String
  type : String  -- Lean type expression
  deriving BEq, Inhabited, Repr

-- Theory definition - the main AST for Lawvere theories
structure Theory where
  name : String
  params : List Param
  ops : List Op
  eqns : List Eqn
  deriving BEq, Inhabited, Repr

-- Helper functions for working with theories
namespace Theory

def findOp (theory : Theory) (name : String) : Option Op :=
  theory.ops.find? (fun op => op.name == name)

def findEqn (theory : Theory) (name : String) : Option Eqn :=
  theory.eqns.find? (fun eqn => eqn.name == name)

def hasOp (theory : Theory) (name : String) : Bool :=
  theory.ops.any (fun op => op.name == name)

def hasEqn (theory : Theory) (name : String) : Bool :=
  theory.eqns.any (fun eqn => eqn.name == name)

-- Check if operation names are unique
def hasUniqueOpNames (theory : Theory) : Bool :=
  let opNames := theory.ops.map (·.name)
  opNames.length == opNames.eraseDups.length

-- Check if equation names are unique
def hasUniqueEqnNames (theory : Theory) : Bool :=
  let eqnNames := theory.eqns.map (·.name)
  eqnNames.length == eqnNames.eraseDups.length

-- Check if parameter names are unique
def hasUniqueParamNames (theory : Theory) : Bool :=
  let paramNames := theory.params.map (·.name)
  paramNames.length == paramNames.eraseDups.length

-- Check if all operation domains and codomains are valid
def hasValidOpTypes (theory : Theory) : Bool :=
  theory.ops.all (fun op => op.name != "" && op.dom.isValid && op.cod.isValid)

-- Overall well-formedness check
def isWellFormed (theory : Theory) : Bool :=
  theory.hasUniqueOpNames &&
  theory.hasUniqueEqnNames &&
  theory.hasUniqueParamNames &&
  theory.hasValidOpTypes

-- Get all operation names
def opNames (theory : Theory) : List String :=
  theory.ops.map (·.name)

-- Get all equation names
def eqnNames (theory : Theory) : List String :=
  theory.eqns.map (·.name)

-- Get all parameter names
def paramNames (theory : Theory) : List String :=
  theory.params.map (·.name)

-- Check if theory is empty (no operations or equations)
def isEmpty (theory : Theory) : Bool :=
  theory.ops.isEmpty && theory.eqns.isEmpty

end Theory

-- Pretty printing functions for debugging and error messages
namespace PrettyPrint

def ppTy : Ty → String
  | .unit => "Unit"
  | .param name => name
  | .prod l r => "(" ++ ppTy l ++ " × " ++ ppTy r ++ ")"
  | .sum l r => "(" ++ ppTy l ++ " + " ++ ppTy r ++ ")"

def ppOp (op : Op) : String :=
  "op " ++ op.name ++ " : " ++ ppTy op.dom ++ " ⟶ " ++ ppTy op.cod

def ppTerm : Term → String
  | .var name => name
  | .unit => "()"
  | .pair l r => "(" ++ ppTerm l ++ ", " ++ ppTerm r ++ ")"
  | .inl t => "inl " ++ ppTerm t
  | .inr t => "inr " ++ ppTerm t
  | .op name args => name ++ "(" ++ ", ".intercalate (args.map ppTerm) ++ ")"
  | .comp f g => ppTerm f ++ " ∘ " ++ ppTerm g
  | .proj1 t => "π₁ " ++ ppTerm t
  | .proj2 t => "π₂ " ++ ppTerm t
  | .case t l r => "case " ++ ppTerm t ++ " of " ++ ppTerm l ++ " | " ++ ppTerm r

def ppEqn (eqn : Eqn) : String :=
  "eq " ++ eqn.name ++ " : " ++ ppTerm eqn.left ++ " = " ++ ppTerm eqn.right

def ppParam (param : Param) : String :=
  param.name ++ " : " ++ param.type

def ppTheory (theory : Theory) : String :=
  let paramsStr := if theory.params.isEmpty then "" else " (" ++ ", ".intercalate (theory.params.map ppParam) ++ ")"
  let opsStr := if theory.ops.isEmpty then "" else "\n  " ++ "\n  ".intercalate (theory.ops.map ppOp)
  let eqnsStr := if theory.eqns.isEmpty then "" else "\n  ".intercalate (theory.eqns.map ppEqn)
  "theory " ++ theory.name ++ paramsStr ++ " where" ++ opsStr ++ eqnsStr ++ "\nend"

-- Error message helpers
def errorInvalidOp (theory : Theory) (opName : String) : String :=
  "Unknown operation '" ++ opName ++ "' in theory '" ++ theory.name ++ "'. Available operations: " ++ ", ".intercalate theory.opNames

def errorInvalidEqn (theory : Theory) (eqnName : String) : String :=
  "Unknown equation '" ++ eqnName ++ "' in theory '" ++ theory.name ++ "'. Available equations: " ++ ", ".intercalate theory.eqnNames

def errorDuplicateOp (opName : String) : String :=
  "Duplicate operation name: " ++ opName

def errorDuplicateEqn (eqnName : String) : String :=
  "Duplicate equation name: " ++ eqnName

def errorDuplicateParam (paramName : String) : String :=
  "Duplicate parameter name: " ++ paramName

def errorInvalidType (ty : Ty) : String :=
  "Invalid type: " ++ ppTy ty

end PrettyPrint

-- Export the main types and functions
export Theory (findOp findEqn hasOp hasEqn isWellFormed)
export PrettyPrint (ppTheory ppTy ppOp ppEqn)

end Effects.DSL
