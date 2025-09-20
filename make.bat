@echo off
REM Windows batch file for lean-effects
REM Provides development, build, and release automation

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="dev" goto dev
if "%1"=="build" goto build
if "%1"=="run" goto run
if "%1"=="test" goto test
if "%1"=="clean" goto clean
if "%1"=="demo" goto demo
if "%1"=="examples" goto examples
if "%1"=="validate" goto validate
if "%1"=="version" goto version
goto unknown

:help
echo lean-effects - Algebraic Effects via Lawvere Theories ^& Handlers
echo.
echo Available targets:
echo   help        Show this help message
echo   dev         Set up local development environment
echo   build       Build the project
echo   run         Run the CLI locally
echo   test        Run the test suite
echo   clean       Clean build artifacts
echo   demo        Run demonstration
echo   examples    Show examples
echo   validate    Validate installation
echo   version     Show version info
echo.
echo Quick start:
echo   make dev    # Set up development environment
echo   make run    # Run the application
echo   make test   # Run tests
goto end

:dev
echo Setting up lean-effects development environment...
echo Checking Lean toolchain...
lean --version
if errorlevel 1 (
    echo Lean not found. Please install Lean 4.8.0+
    goto end
)
echo Updating dependencies...
lake update
echo Building project...
lake build
echo Development environment ready!
echo.
echo Next steps:
echo   make run    # Run the CLI
echo   make test   # Run tests
goto end

:build
echo Building lean-effects...
lake build
echo Build completed!
goto end

:run
echo Running lean-effects CLI...
lake build
lake exe lean-effects
goto end

:demo
echo Running lean-effects demo...
lake build
lake exe lean-effects demo
goto end

:examples
echo Running lean-effects examples...
lake build
lake exe lean-effects examples
goto end

:validate
echo Validating lean-effects installation...
lake build
lake exe lean-effects validate
goto end

:test
echo Running lean-effects test suite...
lake build
lake test
echo All tests passed!
goto end

:clean
echo Cleaning build artifacts...
lake clean
if exist .lake rmdir /s /q .lake
if exist build rmdir /s /q build
echo Clean completed!
goto end

:version
echo lean-effects version info:
findstr "def version" Main.lean
echo Lean toolchain:
type lean-toolchain
goto end

:unknown
echo Unknown command: %1
echo Run 'make help' for available commands
goto end

:end
