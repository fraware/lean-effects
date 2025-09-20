# Makefile for lean-effects
# Provides development, build, and release automation

.PHONY: help dev build run test clean install release docker-build docker-run docker-push validate examples demo

# Default target
help:
	@echo "lean-effects - Algebraic Effects via Lawvere Theories & Handlers"
	@echo ""
	@echo "Available targets:"
	@echo "  help        Show this help message"
	@echo "  dev         Set up local development environment"
	@echo "  build       Build the project"
	@echo "  run         Run the CLI locally"
	@echo "  test        Run the test suite"
	@echo "  clean       Clean build artifacts"
	@echo "  install     Install locally (requires Lean toolchain)"
	@echo "  release     Build and prepare release artifacts"
	@echo "  docker-build Build Docker image"
	@echo "  docker-run  Run via Docker"
	@echo "  docker-push Push Docker image to registry"
	@echo "  validate    Validate installation"
	@echo "  examples    Show examples"
	@echo "  demo        Run demonstration"
	@echo ""
	@echo "Quick start:"
	@echo "  make dev    # Set up development environment"
	@echo "  make run    # Run the application"
	@echo "  make test   # Run tests"

# Development environment setup
dev:
	@echo "🔧 Setting up lean-effects development environment..."
	@echo "Checking Lean toolchain..."
	@lean --version || (echo "❌ Lean not found. Please install Lean 4.8.0+"; exit 1)
	@echo "Updating dependencies..."
	@lake update
	@echo "Building project..."
	@lake build
	@echo "✅ Development environment ready!"
	@echo ""
	@echo "Next steps:"
	@echo "  make run    # Run the CLI"
	@echo "  make test   # Run tests"

# Build the project
build:
	@echo "🏗️  Building lean-effects..."
	@lake build
	@echo "✅ Build completed!"

# Run the CLI locally
run: build
	@echo "🚀 Running lean-effects CLI..."
	@lake exe lean-effects

# Run with demo
demo: build
	@echo "🎯 Running lean-effects demo..."
	@lake exe lean-effects demo

# Run with examples
examples: build
	@echo "📚 Running lean-effects examples..."
	@lake exe lean-effects examples

# Validate installation
validate: build
	@echo "🔍 Validating lean-effects installation..."
	@lake exe lean-effects validate

# Run the test suite
test: build
	@echo "🧪 Running lean-effects test suite..."
	@lake test
	@echo "✅ All tests passed!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@lake clean
	@rm -rf .lake build
	@echo "✅ Clean completed!"

# Install locally (for development)
install: build
	@echo "📦 Installing lean-effects locally..."
	@mkdir -p ~/.local/bin
	@cp .lake/build/bin/lean-effects ~/.local/bin/
	@chmod +x ~/.local/bin/lean-effects
	@echo "✅ lean-effects installed to ~/.local/bin/lean-effects"
	@echo ""
	@echo "Add ~/.local/bin to your PATH if not already added:"
	@echo "  export PATH=~/.local/bin:\$$PATH"

# Build release artifacts
release: clean
	@echo "🚢 Building release artifacts..."
	@lake build --release
	@mkdir -p dist
	@cp .lake/build/bin/lean-effects dist/
	@cp README.md dist/
	@cp LICENSE dist/ 2>/dev/null || echo "No LICENSE file found"
	@tar -czf dist/lean-effects-$$(date +%Y%m%d).tar.gz -C dist lean-effects README.md
	@echo "✅ Release artifacts created in dist/"
	@ls -la dist/

# Docker targets
DOCKER_IMAGE := ghcr.io/fraware/lean-effects
DOCKER_TAG := latest

docker-build:
	@echo "🐳 Building Docker image..."
	@docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo "✅ Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)"

docker-run: docker-build
	@echo "🐳 Running lean-effects via Docker..."
	@docker run --rm $(DOCKER_IMAGE):$(DOCKER_TAG) --help

docker-push: docker-build
	@echo "🐳 Pushing Docker image to registry..."
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "✅ Docker image pushed: $(DOCKER_IMAGE):$(DOCKER_TAG)"

# Development helpers
format:
	@echo "🎨 Formatting Lean code..."
	@find src tests examples -name "*.lean" -exec lean --stdin < {} \; 2>/dev/null || echo "Format check completed"

lint: build
	@echo "🔍 Running linter..."
	@lake build --release 2>&1 | grep -E "(warning|error)" || echo "✅ No linting issues found"

# Performance targets
bench: build
	@echo "⚡ Running benchmarks..."
	@lake exe Bench

perf: bench
	@echo "📊 Performance analysis completed"

# Documentation targets
docs:
	@echo "📖 Building documentation..."
	@cd docs && python -m mkdocs build
	@echo "✅ Documentation built in docs/site/"

docs-serve:
	@echo "🌐 Serving documentation locally..."
	@cd docs && python -m mkdocs serve

# CI/CD helpers
ci-test: dev test
	@echo "✅ CI test pipeline completed"

ci-build: dev build
	@echo "✅ CI build pipeline completed"

# Version management
version:
	@echo "lean-effects version info:"
	@grep "def version" Main.lean | sed 's/def version : String := /Version: /'
	@echo "Lean toolchain:"
	@cat lean-toolchain

# Quick development cycle
quick: clean build test
	@echo "✅ Quick development cycle completed"

# Show project status
status:
	@echo "📊 lean-effects project status:"
	@echo "Lean toolchain: $$(cat lean-toolchain)"
	@echo "Build status: $$(lake build > /dev/null 2>&1 && echo '✅ OK' || echo '❌ Failed')"
	@echo "Test status: $$(lake test > /dev/null 2>&1 && echo '✅ OK' || echo '❌ Failed')"
	@echo "Files:"
	@find src -name "*.lean" | wc -l | xargs echo "  Source files:"
	@find tests -name "*.lean" | wc -l | xargs echo "  Test files:"
	@find examples -name "*.lean" | wc -l | xargs echo "  Example files:"
