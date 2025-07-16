#!/bin/bash
# Simple test script for UserCanal Swift SDK
# Replaces overcomplicated test-runner.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "UserCanal Swift SDK Test Script"
    echo ""
    echo "Usage: ./test.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  -c, --clean    Clean before testing"
    echo "  --coverage     Generate code coverage"
    echo "  --filter TEST  Run specific test"
    echo ""
    echo "Examples:"
    echo "  ./test.sh                           # Run all tests"
    echo "  ./test.sh --clean                   # Clean and test"
    echo "  ./test.sh --filter EventDomainTests # Run specific test"
    echo "  ./test.sh --coverage                # Generate coverage"
    echo ""
    echo "Note: This just wraps 'swift test' with convenience options."
    echo "You can also run 'swift test' directly."
    exit 0
fi

# Parse options
CLEAN=false
COVERAGE=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean) CLEAN=true; shift ;;
        --coverage) COVERAGE=true; shift ;;
        --filter) FILTER="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Clean if requested
if [[ "$CLEAN" == "true" ]]; then
    log "Cleaning build artifacts..."
    swift package clean
    rm -rf .build
fi

# Generate FlatBuffers if needed
if [[ -f "Makefile" ]]; then
    log "Generating FlatBuffers code..."
    make generate-flatbuffers || {
        error "FlatBuffers generation failed. Install with: brew install flatbuffers"
        exit 1
    }
fi

# Build args
BUILD_ARGS=""
if [[ "$COVERAGE" == "true" ]]; then
    BUILD_ARGS="--enable-code-coverage"
fi

# Test args
TEST_ARGS="$BUILD_ARGS"
if [[ -n "$FILTER" ]]; then
    TEST_ARGS="$TEST_ARGS --filter $FILTER"
fi

# Run tests
log "Running tests..."
if swift test $TEST_ARGS; then
    success "All tests passed!"
    
    if [[ "$COVERAGE" == "true" ]]; then
        log "Code coverage enabled. Results in .build/debug/codecov/"
    fi
else
    error "Tests failed!"
    exit 1
fi