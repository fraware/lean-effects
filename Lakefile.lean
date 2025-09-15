import Lake
open Lake DSL

package «lean-effects» where
  -- add package configuration options here

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.8.0"

@[default_target]
lean_lib «Effects» where
  srcDir := "src"
  -- add library configuration options here

lean_lib «Tests» where
  srcDir := "tests"
  -- add library configuration options here

-- Benchmark target
lean_exe «Bench» where
  root := `Bench
  supportInterpreter := true
