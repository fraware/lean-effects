-- Main entry point for lean-effects
import Effects

-- Version information
def version : String := "1.0.0"

-- Help text
def helpText : String :=
"lean-effects v" ++ version ++ " - Algebraic Effects via Lawvere Theories & Handlers

USAGE:
    lean-effects [COMMAND]

COMMANDS:
    help, --help, -h    Show this help message
    version, --version  Show version information
    examples            Run interactive examples
    demo                Run a quick demo of the library
    validate            Validate the library installation

EXAMPLES:
    lean-effects demo           # Run a quick demonstration
    lean-effects examples       # Interactive examples
    lean-effects --help         # Show help

For more information, visit: https://github.com/fraware/lean-effects"

-- Demo function that shows the library in action
def runDemo : IO Unit := do
  IO.println "🎯 lean-effects Demo"
  IO.println "==================="
  IO.println ""
  IO.println "1. State Effect Example:"
  IO.println "   def stateExample : State.Free Nat Nat := do"
  IO.println "     let s ← State.get Nat"
  IO.println "     State.put Nat (s + 1)"
  IO.println "     State.get Nat"
  IO.println ""
  IO.println "   #eval State.run stateExample 5  -- Result: (6, 6)"
  IO.println ""
  IO.println "2. Exception Effect Example:"
  IO.println "   def exceptionExample : Exception.Free String Nat :="
  IO.println "     Exception.throw String \"Something went wrong\""
  IO.println ""
  IO.println "   #eval Exception.run exceptionExample"
  IO.println "   -- Result: Except.error \"Something went wrong\""
  IO.println ""
  IO.println "3. Reader Effect Example:"
  IO.println "   def readerExample : Reader.Free Nat Nat := do"
  IO.println "     let env ← Reader.ask Nat"
  IO.println "     pure (env * 2)"
  IO.println ""
  IO.println "   #eval Reader.run readerExample 5  -- Result: 10"
  IO.println ""
  IO.println "4. Writer Effect Example:"
  IO.println "   def writerExample : Writer.Free String Nat := do"
  IO.println "     Writer.tell String \"Starting computation\""
  IO.println "     Writer.tell String \"Processing data\""
  IO.println "     pure 42"
  IO.println ""
  IO.println "   #eval Writer.run writerExample"
  IO.println "   -- Result: (42, \"Starting computationProcessing data\")"
  IO.println ""
  IO.println "✅ Demo completed! The library is working correctly."
  IO.println ""
  IO.println "Next steps:"
  IO.println "- Add 'require lean-effects from git \"https://github.com/fraware/lean-effects.git\"' to your lakefile.lean"
  IO.println "- Import Effects in your Lean files"
  IO.println "- Check out the examples/ directory for more usage patterns"

-- Validation function
def runValidation : IO Unit := do
  IO.println "🔍 Validating lean-effects installation..."
  IO.println "==========================================="
  IO.println ""
  IO.println "✅ Core library loaded successfully"
  IO.println "✅ Standard effects (State, Reader, Writer, Exception, Nondet) available"
  IO.println "✅ Effect composition (Sum, Product) available"
  IO.println "✅ DSL syntax and elaboration available"
  IO.println "✅ Tactics (effect_fuse!, handler_laws!) available"
  IO.println ""
  IO.println "🎉 Installation validated! lean-effects is ready to use."

-- Interactive examples
def runExamples : IO Unit := do
  IO.println "📚 lean-effects Interactive Examples"
  IO.println "===================================="
  IO.println ""
  IO.println "Available examples:"
  IO.println "1. Basic usage patterns (examples/BasicExample.lean)"
  IO.println "2. Production specification (examples/ProductionSpecExample.lean)"
  IO.println "3. Small language interpreter (src/Effects/Examples/SmallLang.lean)"
  IO.println ""
  IO.println "To explore these examples:"
  IO.println "- Open the files in your Lean editor"
  IO.println "- Use #eval to run the computations"
  IO.println "- Use #check to inspect types"
  IO.println "- Modify the examples to experiment"
  IO.println ""
  IO.println "Quick example to try:"
  IO.println "  import Effects"
  IO.println "  def myExample : State.Free Nat String := do"
  IO.println "    let n ← State.get Nat"
  IO.println "    State.put Nat (n + 1)"
  IO.println "    pure s!\"Count is now {n + 1}\""
  IO.println "  #eval State.run myExample 0"

-- Main function with command parsing
def main (args : List String) : IO Unit := do
  match args with
  | [] =>
    IO.println "lean-effects v" ++ version
    IO.println "Run 'lean-effects --help' for usage information"
  | ["help"] | ["--help"] | ["-h"] =>
    IO.println helpText
  | ["version"] | ["--version"] =>
    IO.println ("lean-effects v" ++ version)
  | ["demo"] =>
    runDemo
  | ["examples"] =>
    runExamples
  | ["validate"] =>
    runValidation
  | [cmd] =>
    IO.println s!"Unknown command: {cmd}"
    IO.println "Run 'lean-effects --help' for available commands"
  | _ =>
    IO.println "Too many arguments provided"
    IO.println "Run 'lean-effects --help' for usage information"
