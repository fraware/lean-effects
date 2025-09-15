# First Example

This guide walks through a complete example of using lean-effects to build a simple calculator with logging and error handling.

## The Problem

We want to build a calculator that:
1. Tracks the current value in state
2. Logs all operations
3. Handles division by zero errors
4. Supports basic arithmetic operations

## Step 1: Define the Effects

First, let's define our custom effects:

```lean
import Effects.Std

-- Calculator state effect
theory Calculator where
  op get_value : Unit ⟶ Nat
  op set_value : Nat ⟶ Unit
  op add : Nat ⟶ Unit
  op multiply : Nat ⟶ Unit
end

-- Arithmetic operations effect
theory Arithmetic where
  op divide : Nat ⟶ Nat
  op subtract : Nat ⟶ Nat
end

-- Generate the free monads and handlers
derive_effect Calculator [free, handler, fusion, simp]
derive_effect Arithmetic [free, handler, fusion, simp]
```

## Step 2: Compose Effects

Combine our effects with standard ones:

```lean
-- Combine calculator state with logging and exceptions
def CalculatorWithLogging := 
  SumTheory (SumTheory Calculator Arithmetic) (SumTheory Writer Exception)

-- Type alias for convenience
abbrev CalculatorProgram α := CalculatorWithLogging.Free α
```

## Step 3: Implement the Calculator Logic

```lean
-- Calculator operations
def addToCalculator (n : Nat) : CalculatorProgram Unit := do
  let current ← Calculator.get_value
  Calculator.set_value (current + n)
  Writer.tell [s!"Added {n}, new value: {current + n}"]

def multiplyCalculator (n : Nat) : CalculatorProgram Unit := do
  let current ← Calculator.get_value
  Calculator.set_value (current * n)
  Writer.tell [s!"Multiplied by {n}, new value: {current * n}"]

def divideCalculator (n : Nat) : CalculatorProgram Unit := do
  if n == 0 then
    Exception.throw "Division by zero"
  else
    let current ← Calculator.get_value
    let result := current / n
    Calculator.set_value result
    Writer.tell [s!"Divided by {n}, new value: {result}"]

def subtractCalculator (n : Nat) : CalculatorProgram Unit := do
  let current ← Calculator.get_value
  if n > current then
    Exception.throw "Subtraction would result in negative number"
  else
    Calculator.set_value (current - n)
    Writer.tell [s!"Subtracted {n}, new value: {current - n}"]
```

## Step 4: Create Handlers

```lean
-- Handler for calculator state
def calculatorHandler (init : Nat) : Calculator.Handler (State Nat) where
  handle op := match op with
    | Calculator.get_value => State.get
    | Calculator.set_value n => State.put n
    | Calculator.add n => do
        let current ← State.get
        State.put (current + n)
    | Calculator.multiply n => do
        let current ← State.get
        State.put (current * n)

-- Handler for arithmetic operations
def arithmeticHandler : Arithmetic.Handler Id where
  handle op := match op with
    | Arithmetic.divide n => fun x => x / n
    | Arithmetic.subtract n => fun x => x - n

-- Handler for logging
def loggingHandler : Writer.Handler (List String) Id where
  handle op := match op with
    | Writer.tell msgs => fun _ => ((), msgs)

-- Handler for exceptions
def exceptionHandler : Exception.Handler String (Option α) where
  handle op := match op with
    | Exception.throw msg => fun _ => none
```

## Step 5: Run the Calculator

```lean
-- Main calculator program
def calculatorProgram : CalculatorProgram Unit := do
  addToCalculator 10
  multiplyCalculator 2
  divideCalculator 3
  subtractCalculator 1
  let final ← Calculator.get_value
  Writer.tell [s!"Final result: {final}"]

-- Run the calculator
def runCalculator (init : Nat) : CalculatorProgram α → Option (α × List String) :=
  CalculatorWithLogging.fold 
    (init, [])  -- Initial state and empty log
    (fun (state, log) => 
      -- Calculator handler
      Calculator.fold (calculatorHandler state) $
      -- Arithmetic handler  
      Arithmetic.fold arithmeticHandler $
      -- Writer handler
      Writer.fold loggingHandler $
      -- Exception handler
      Exception.fold exceptionHandler $
      -- Return result with log
      fun result => (result, log))

-- Example usage
def main : IO Unit := do
  let result := runCalculator 0 calculatorProgram
  match result with
  | some (_, log) => 
      IO.println "Calculator completed successfully:"
      log.forM IO.println
  | none => 
      IO.println "Calculator failed with error"
```

## Step 6: Test the Calculator

```lean
-- Test cases
def testCalculator : IO Unit := do
  -- Test 1: Normal operation
  let result1 := runCalculator 0 calculatorProgram
  IO.println s!"Test 1 result: {result1}"
  
  -- Test 2: Division by zero
  let divByZeroProgram : CalculatorProgram Unit := do
    Calculator.set_value 10
    divideCalculator 0
  
  let result2 := runCalculator 0 divByZeroProgram
  IO.println s!"Test 2 result (should be none): {result2}"

#eval testCalculator
```

## Key Takeaways

1. **Effect Definition**: Use `theory` to define operations and equations
2. **Code Generation**: Use `derive_effect` to generate free monads and handlers
3. **Composition**: Combine effects using `SumTheory` and `ProdTheory`
4. **Handlers**: Implement handlers to interpret effects in different monads
5. **Fusion**: Use `fold` to compose handlers and run programs

## Next Steps

- Explore the [Standard Library](api/state.md) for more effects
- Learn about [Common Patterns](cookbook/common-patterns.md)
- Check out [Performance Tips](cookbook/performance.md)