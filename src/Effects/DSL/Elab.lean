-- DSL elaboration and desugaring for Lawvere theories
import Effects.DSL.Syntax
import Lean
import Lean.Elab.Command
import Lean.Elab.Term
import Lean.Elab.DeclarationRange

open Lean
open Lean.Elab
open Lean.Elab.Command
open Lean.Elab.Term

namespace Effects.DSL

-- Theory command syntax
syntax "theory " ident " (" (ident " : " term),* ")" " where" (command)* "end" : command

-- Operation syntax
syntax "op " ident " : " term " ⟶ " term : command

-- Equation syntax
syntax "eq " ident " : " term " = " term : command

-- Derive effect command syntax
syntax "derive_effect " ident " [" ident,* "]" : command

-- Theory state for tracking theories during elaboration
structure TheoryState where
  name : String
  params : List (String × String)  -- (name, type)
  ops : List (String × String × String)  -- (name, dom, cod)
  eqns : List (String × String × String)  -- (name, left, right)
  deriving Inhabited

-- Global state for current theory being elaborated
private def currentTheoryRef : IO.Ref (Option TheoryState) :=
  unsafePerformIO (IO.mkRef none)

-- Global state for completed theories
private def theoriesRef : IO.Ref (List (String × Theory)) :=
  unsafePerformIO (IO.mkRef [])

-- Type parsing functions
partial def parseType (s : String) : Ty :=
  let trimmed := s.trim
  if trimmed == "Unit" || trimmed == "()" then
    Ty.unit
  else if trimmed.contains "×" then
    let parts := trimmed.splitOn "×"
    if parts.length == 2 then
      Ty.prod (parseType parts[0]!.trim) (parseType parts[1]!.trim)
    else
      Ty.param trimmed
  else if trimmed.contains "+" then
    let parts := trimmed.splitOn "+"
    if parts.length == 2 then
      Ty.sum (parseType parts[0]!.trim) (parseType parts[1]!.trim)
    else
      Ty.param trimmed
  else
    Ty.param trimmed

-- Term parsing functions
partial def parseTerm (s : String) : Term :=
  let trimmed := s.trim
  if trimmed == "()" || trimmed == "unit" then
    Term.unit
  else if trimmed.contains "(" && trimmed.contains ")" then
    -- Function application or pair
    if trimmed.contains "," then
      -- Pair construction
      let inner := trimmed.drop 1.dropRight 1 -- Remove parentheses
      let parts := inner.splitOn ","
      if parts.length == 2 then
        Term.pair (parseTerm parts[0]!.trim) (parseTerm parts[1]!.trim)
      else
        Term.var trimmed
    else
      -- Function application
      let parts := trimmed.splitOn "("
      if parts.length == 2 then
        let funcName := parts[0]!.trim
        let argsStr := parts[1]!.dropRight 1 -- Remove closing paren
        if argsStr.isEmpty then
          Term.op funcName []
        else
          let args := argsStr.splitOn "," |>.map parseTerm
          Term.op funcName args
      else
        Term.var trimmed
  else if trimmed.contains "∘" then
    let parts := trimmed.splitOn "∘"
    if parts.length == 2 then
      Term.comp (parseTerm parts[0]!.trim) (parseTerm parts[1]!.trim)
    else
      Term.var trimmed
  else if trimmed.startsWith "π₁ " then
    Term.proj1 (parseTerm (trimmed.drop 3))
  else if trimmed.startsWith "π₂ " then
    Term.proj2 (parseTerm (trimmed.drop 3))
  else if trimmed.startsWith "inl " then
    Term.inl (parseTerm (trimmed.drop 4))
  else if trimmed.startsWith "inr " then
    Term.inr (parseTerm (trimmed.drop 4))
  else if trimmed.startsWith "case " then
    -- Parse case expressions: case t of l | r
    let withoutCase := trimmed.drop 5
    let parts := withoutCase.splitOn " of "
    if parts.length == 2 then
      let scrutinee := parseTerm parts[0]!.trim
      let branches := parts[1]!.splitOn " | "
      if branches.length == 2 then
        Term.case scrutinee (parseTerm branches[0]!.trim) (parseTerm branches[1]!.trim)
      else
        Term.var trimmed
    else
      Term.var trimmed
  else
    Term.var trimmed

-- Operation elaboration
@[command_elab «op»]
def elabOp : CommandElab := fun stx => do
  match stx with
  | `(op $name : $dom ⟶ $cod) => do
    let opName := name.getId.toString
    let domStr := dom.raw.reprint.getD ""
    let codStr := cod.raw.reprint.getD ""

    let currentTheory ← currentTheoryRef.get
    match currentTheory with
    | none => throwError "Operation '{opName}' defined outside of theory"
    | some theory => do
      let newTheory := { theory with ops := theory.ops ++ [(opName, domStr, codStr)] }
      currentTheoryRef.set (some newTheory)
      logInfo ("Added operation '{opName}' to theory '{theory.name}'")
  | _ => throwError "Invalid operation syntax: {stx}"

-- Equation elaboration
@[command_elab «eq»]
def elabEqn : CommandElab := fun stx => do
  match stx with
  | `(eq $name : $left = $right) => do
    let eqnName := name.getId.toString
    let leftStr := left.raw.reprint.getD ""
    let rightStr := right.raw.reprint.getD ""

    let currentTheory ← currentTheoryRef.get
    match currentTheory with
    | none => throwError "Equation '{eqnName}' defined outside of theory"
    | some theory => do
      let newTheory := { theory with eqns := theory.eqns ++ [(eqnName, leftStr, rightStr)] }
      currentTheoryRef.set (some newTheory)
      logInfo ("Added equation '{eqnName}' to theory '{theory.name}'")
  | _ => throwError "Invalid equation syntax: {stx}"

-- Main theory elaboration
@[command_elab «theory»]
def elabTheory : CommandElab := fun stx => do
  match stx with
  | `(theory $name ($params,*) where $body* end) => do
    let theoryName := name.getId.toString

    -- Parse parameters
    let paramList : List (String × String) := params.getElems.map fun param =>
      match param with
      | `($paramName : $paramType) => (paramName.getId.toString, paramType.raw.reprint.getD "")
      | _ => ("", "")

    -- Initialize theory state
    let theoryState : TheoryState := {
      name := theoryName
      params := paramList
      ops := []
      eqns := []
    }

    -- Set current theory
    currentTheoryRef.set (some theoryState)

    -- Elaborate body commands
    for cmd in body do
      elabCommand cmd

    -- Get final theory state
    let finalTheory ← currentTheoryRef.get
    match finalTheory with
    | none => throwError "Theory state lost during elaboration"
    | some theory => do
      -- Convert to Theory AST
      let theoryAST : Theory := {
        name := theory.name
        params := theory.params.map fun (name, type) => { name := name, type := type }
        ops := theory.ops.map fun (name, dom, cod) =>
          { name := name, dom := parseType dom, cod := parseType cod }
        eqns := theory.eqns.map fun (name, left, right) =>
          { name := name, left := parseTerm left, right := parseTerm right }
      }

      -- Store completed theory
      let theories ← theoriesRef.get
      let newTheories := theories ++ [(theoryName, theoryAST)]
      theoriesRef.set newTheories

      -- Clear current theory
      currentTheoryRef.set none

      logInfo ("Completed theory '{theoryName}' with {theory.ops.length} operations and {theory.eqns.length} equations")

  | `(theory $name where $body* end) => do
    -- Theory without parameters
    elabTheory (← `(theory $name () where $body* end))

  | _ => throwError "Invalid theory syntax: {stx}"

-- Code generation functions
def generateFreeMonad (theoryName : String) : CommandElabM Unit := do
  let freeName := s!"{theoryName}.Free"
  let sigName := s!"{theoryName}Sig"

  -- Get the theory to generate proper signature
  let theories ← theoriesRef.get
  match theories.find? (fun (n, _) => n == theoryName) with
  | none => throwError "Theory '{theoryName}' not found for code generation"
  | some (_, theory) => do
    -- Generate signature based on operations
    let sigDef := s!"
-- Signature for {theoryName} effect
inductive {sigName} (α : Type u) where"

    let opsDef := theory.ops.map fun op =>
      s!"  | {op.name} : {op.dom} → {sigName} α"
    let sigComplete := sigDef ++ "\n" ++ "\n".intercalate opsDef

    -- Generate functor instance
    let functorDef := s!"
-- Functor instance for {sigName}
instance : Functor {sigName} where
  map f := fun m => match m with"

    let functorCases := theory.ops.map fun op =>
      s!"    | .{op.name} x => .{op.name} x"
    let functorComplete := functorDef ++ "\n" ++ "\n".intercalate functorCases

    -- Generate free monad
    let freeDef := s!"
-- Free monad for {theoryName}
def {freeName} (α : Type u) : Type u :=
  Effects.Core.FreeMonad {sigName} α"

    -- Generate operations
    let opsDef := theory.ops.map fun op =>
      s!"
def {theoryName}.{op.name} (α : Type u) : {op.dom} → {freeName} α :=
  fun x => Effects.Core.FreeMonad.op ({sigName}.{op.name} x)"

    let opsComplete := "\n".intercalate opsDef

    let code := sigComplete ++ functorComplete ++ freeDef ++ opsComplete

    -- Parse and add the generated code
    let stx := Lean.Parser.runParserCategory (← getEnv) `command code
    elabCommand stx

def generateHandler (theoryName : String) : CommandElabM Unit := do
  let freeName := s!"{theoryName}.Free"
  let sigName := s!"{theoryName}Sig"
  let handlerName := s!"{theoryName}.handle"

  -- Get the theory to generate proper handler
  let theories ← theoriesRef.get
  match theories.find? (fun (n, _) => n == theoryName) with
  | none => throwError "Theory '{theoryName}' not found for handler generation"
  | some (_, theory) => do
    let code := s!"
-- Handler for {theoryName}
def {handlerName} [Monad M] (interpretOp : {sigName} α → M α) (m : {freeName} α) : M α :=
  match m with
  | .pure x => pure x
  | .impure sig k => do
    let x ← interpretOp sig
    {handlerName} interpretOp (k x)

-- Generic handler interface
instance [Monad M] (interpretOp : {sigName} α → M α) : Effects.Core.Handler {sigName} M where
  interpret := {handlerName} interpretOp
  interpret_pure := by simp [{handlerName}]
  interpret_bind := by
    intro m f
    induction m with
    | pure x => simp [{handlerName}]
    | impure sig k ih => simp [{handlerName}]; congr 1; ext y; exact ih y

-- Handler laws
theorem {theoryName}_handler_pure [Monad M] (interpretOp : {sigName} α → M α) (x : α) :
  {handlerName} interpretOp (Effects.Core.FreeMonad.pure x) = pure x := by
  simp [{handlerName}, Effects.Core.FreeMonad.pure]

theorem {theoryName}_handler_bind [Monad M] (interpretOp : {sigName} α → M α) (m : {freeName} α) (f : α → {freeName} β) :
  {handlerName} interpretOp (Effects.Core.FreeMonad.bind m f) = bind ({handlerName} interpretOp m) (fun x => {handlerName} interpretOp (f x)) := by
  simp [{handlerName}, Effects.Core.FreeMonad.bind]
"

    -- Parse and add the generated code
    let stx := Lean.Parser.runParserCategory (← getEnv) `command code
    elabCommand stx

def generateFusion (theoryName : String) : CommandElabM Unit := do
  let freeName := s!"{theoryName}.Free"
  let sigName := s!"{theoryName}Sig"

  let code := s!"
-- Fusion theorems for {theoryName}
theorem {theoryName}_map_fusion [Monad M] [Monad N] (interpretOp : {sigName} α → M α) (h : M α → N α) (f : α → β) (m : {freeName} α) :
  h (f <$> {theoryName}.handle interpretOp m) = f <$> h ({theoryName}.handle interpretOp m) := by
  simp [{theoryName}.handle, Functor.map]

theorem {theoryName}_bind_fusion [Monad M] [Monad N] (interpretOp : {sigName} α → M α) (h : M α → N α) (f : α → {freeName} β) (m : {freeName} α) :
  h ({theoryName}.handle interpretOp m >>= (fun x => {theoryName}.handle interpretOp (f x))) = h ({theoryName}.handle interpretOp m) >>= (fun x => h ({theoryName}.handle interpretOp (f x))) := by
  simp [{theoryName}.handle, bind]

theorem {theoryName}_fold_fusion [Monad M] [Monad N] (interpretOp : {sigName} α → M α) (φ : {sigName} (N α) → N α) (h : M α → N α) :
  h ∘ {theoryName}.handle interpretOp = Effects.Core.FreeMonad.fold φ ∘ Effects.Core.FreeMonad.mapM h := by
  ext m
  induction m with
  | pure x => simp [{theoryName}.handle, Effects.Core.FreeMonad.fold, Effects.Core.FreeMonad.mapM]
  | impure sig k ih => simp [{theoryName}.handle, Effects.Core.FreeMonad.fold, Effects.Core.FreeMonad.mapM]; congr 1; ext y; exact ih y
"

  -- Parse and add the generated code
  let stx := Lean.Parser.runParserCategory (← getEnv) `command code
  elabCommand stx

def generateSimp (theoryName : String) : CommandElabM Unit := do
  let freeName := s!"{theoryName}.Free"

  let code := s!"
-- Simplification lemmas for {theoryName}
@[simp]
theorem {theoryName}_pure_bind (x : α) (f : α → {freeName} β) :
  Effects.Core.FreeMonad.bind (Effects.Core.FreeMonad.pure x : {freeName} α) f = f x := by
  simp [Effects.Core.FreeMonad.bind, Effects.Core.FreeMonad.pure, Effects.Core.FreeMonad.pure_bind]

@[simp]
theorem {theoryName}_bind_pure (m : {freeName} α) :
  Effects.Core.FreeMonad.bind m Effects.Core.FreeMonad.pure = m := by
  simp [Effects.Core.FreeMonad.bind, Effects.Core.FreeMonad.pure, Effects.Core.FreeMonad.bind_pure]

@[simp]
theorem {theoryName}_bind_assoc (m : {freeName} α) (f : α → {freeName} β) (g : β → {freeName} γ) :
  Effects.Core.FreeMonad.bind (Effects.Core.FreeMonad.bind m f) g = Effects.Core.FreeMonad.bind m (fun x => Effects.Core.FreeMonad.bind (f x) g) := by
  simp [Effects.Core.FreeMonad.bind, Effects.Core.FreeMonad.bind_assoc]

@[simp]
theorem {theoryName}_map_id (m : {freeName} α) :
  id <$> m = m := by
  simp [Effects.Core.FreeMonad.map, Effects.Core.FreeMonad.map_id]

@[simp]
theorem {theoryName}_map_comp (f : α → β) (g : β → γ) (m : {freeName} α) :
  (g ∘ f) <$> m = g <$> (f <$> m) := by
  simp [Effects.Core.FreeMonad.map, Effects.Core.FreeMonad.map_comp]
"

  -- Parse and add the generated code
  let stx := Lean.Parser.runParserCategory (← getEnv) `command code
  elabCommand stx

-- Derive effect command elaboration
@[command_elab «derive_effect»]
def elabDeriveEffect : CommandElab := fun stx => do
  match stx with
  | `(derive_effect $name [$options,*]) => do
    let theoryName := name.getId.toString
    let optionsList := options.getElems.map (·.getId.toString)

    -- Look up theory
    let theories ← theoriesRef.get
    match theories.find? (fun (n, _) => n == theoryName) with
    | none => throwError "Theory '{theoryName}' not found. Available theories: {theories.map (·.1)}"
    | some (_, theory) => do
      -- Validate options
      let validOptions := ["free", "handler", "fusion", "simp"]
      let invalidOptions := optionsList.filter (fun opt => !validOptions.contains opt)
      if !invalidOptions.isEmpty then
        throwError "Invalid options: {invalidOptions}. Valid options: {validOptions}"

      -- Generate code based on options
      if optionsList.contains "free" then
        generateFreeMonad theoryName
        logInfo ("Generated free monad for theory '{theory.name}'")

      if optionsList.contains "handler" then
        generateHandler theoryName
        logInfo ("Generated handler interface for theory '{theory.name}'")

      if optionsList.contains "fusion" then
        generateFusion theoryName
        logInfo ("Generated fusion theorems for theory '{theory.name}'")

      if optionsList.contains "simp" then
        generateSimp theoryName
        logInfo ("Generated simplification pack for theory '{theory.name}'")

      logInfo ("Generated code for theory '{theoryName}' with options: {optionsList}")

  | _ => throwError "Invalid derive_effect syntax: {stx}"

-- Helper functions for theory lookup
def findTheory (name : String) : CommandElabM Theory := do
  let theories ← theoriesRef.get
  match theories.find? (fun (n, _) => n == name) with
  | none => throwError "Theory '{name}' not found"
  | some (_, theory) => return theory

def listTheories : CommandElabM (List String) := do
  let theories ← theoriesRef.get
  return theories.map (·.1)

-- Export functions for use in other modules
export findTheory listTheories

end Effects.DSL
