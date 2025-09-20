# Dockerfile for lean-effects
# Multi-stage build for optimized container size

# Stage 1: Build stage
FROM ubuntu:22.04 AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Lean 4
RUN curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
ENV PATH="/root/.elan/bin:${PATH}"

# Set working directory
WORKDIR /app

# Copy lean-toolchain first to leverage Docker layer caching
COPY lean-toolchain .

# Install the specific Lean version
RUN elan install $(cat lean-toolchain) && elan default $(cat lean-toolchain)

# Copy Lake configuration
COPY Lakefile.lean lake-manifest.json ./

# Update dependencies
RUN lake update

# Copy source code
COPY src/ src/
COPY Main.lean .
COPY test.lean .

# Copy examples and tests (optional, for validation)
COPY examples/ examples/
COPY tests/ tests/

# Build the project
RUN lake build --release

# Stage 2: Runtime stage
FROM ubuntu:22.04

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 leanuser

# Copy the built executable from builder stage
COPY --from=builder /app/.lake/build/bin/lean-effects /usr/local/bin/lean-effects

# Copy documentation and examples for reference
COPY --from=builder /app/examples/ /opt/lean-effects/examples/
COPY README.md /opt/lean-effects/

# Set proper permissions
RUN chmod +x /usr/local/bin/lean-effects

# Switch to non-root user
USER leanuser

# Set working directory
WORKDIR /home/leanuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD lean-effects validate || exit 1

# Default command
ENTRYPOINT ["lean-effects"]
CMD ["--help"]

# Metadata
LABEL org.opencontainers.image.title="lean-effects"
LABEL org.opencontainers.image.description="Algebraic Effects via Lawvere Theories & Handlers in Lean 4"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="fraware"
LABEL org.opencontainers.image.url="https://github.com/fraware/lean-effects"
LABEL org.opencontainers.image.source="https://github.com/fraware/lean-effects"
LABEL org.opencontainers.image.licenses="MIT"
