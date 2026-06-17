import Lake
open Lake DSL

package «lean-effects» where
  -- add package configuration options here

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.31.0"

@[default_target]
lean_lib «Effects» where
  srcDir := "src"

@[default_target]
lean_lib «Tests» where
  srcDir := "tests"

@[default_target]
lean_exe «lean-effects» where
  root := `Main
  supportInterpreter := true

lean_exe «Bench» where
  root := `Benchmarks
  srcDir := "bench"
  supportInterpreter := true

lean_exe «performance-monitor» where
  root := `PerformanceMonitor
  srcDir := "scripts"
  supportInterpreter := true

lean_exe «coverage-report» where
  root := `CoverageReport
  srcDir := "scripts"
  supportInterpreter := true

lean_exe «generate-docs» where
  root := `GenerateDocs
  srcDir := "scripts"
  supportInterpreter := true

lean_exe «build-release» where
  root := `BuildRelease
  srcDir := "scripts"
  supportInterpreter := true

lean_exe «test-suite» where
  root := `TestSuite
  srcDir := "scripts"
  supportInterpreter := true
