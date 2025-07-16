# Makefile for UserCanal Swift SDK
# This handles FlatBuffers code generation and other build tasks

# FlatBuffers compiler
FLATC ?= flatc

# Directories
SCHEMA_DIR = schema
GENERATED_DIR = Sources/UserCanal/Generated
SWIFT_PACKAGE_DIR = .

# Schema files
SCHEMA_FILES = $(wildcard $(SCHEMA_DIR)/*.fbs)

# Generated Swift files (will be created by flatc)
GENERATED_FILES = $(GENERATED_DIR)/schema_common_generated.swift \
                  $(GENERATED_DIR)/schema_event_generated.swift \
                  $(GENERATED_DIR)/schema_log_generated.swift

.PHONY: all clean generate-flatbuffers test build install-flatc help

# Default target
all: generate-flatbuffers

# Generate FlatBuffers Swift code from schema files
generate-flatbuffers: $(GENERATED_FILES)

$(GENERATED_DIR)/schema_common_generated.swift: $(SCHEMA_DIR)/common.fbs | $(GENERATED_DIR)
	$(FLATC) --swift -o $(GENERATED_DIR) $<

$(GENERATED_DIR)/schema_event_generated.swift: $(SCHEMA_DIR)/event.fbs $(SCHEMA_DIR)/common.fbs | $(GENERATED_DIR)
	$(FLATC) --swift -o $(GENERATED_DIR) $<

$(GENERATED_DIR)/schema_log_generated.swift: $(SCHEMA_DIR)/log.fbs $(SCHEMA_DIR)/common.fbs | $(GENERATED_DIR)
	$(FLATC) --swift -o $(GENERATED_DIR) $<

# Create generated directory
$(GENERATED_DIR):
	mkdir -p $(GENERATED_DIR)

# Clean generated files
clean:
	rm -rf $(GENERATED_DIR)
	rm -rf .build

# Run tests
test: generate-flatbuffers
	swift test

# Build the package
build: generate-flatbuffers
	swift build

# Install FlatBuffers compiler (macOS with Homebrew)
install-flatc:
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing FlatBuffers with Homebrew..."; \
		brew install flatbuffers; \
	else \
		echo "Homebrew not found. Please install FlatBuffers manually:"; \
		echo "https://google.github.io/flatbuffers/flatbuffers_guide_building.html"; \
	fi

# Check if flatc is available
check-flatc:
	@if command -v $(FLATC) >/dev/null 2>&1; then \
		echo "FlatBuffers compiler found: $$($(FLATC) --version)"; \
	else \
		echo "Error: FlatBuffers compiler (flatc) not found."; \
		echo "Please install it using 'make install-flatc' or manually."; \
		exit 1; \
	fi

# Validate schema files
validate-schema: check-flatc
	@echo "Validating schema files..."
	@for schema in $(SCHEMA_FILES); do \
		echo "Validating $$schema..."; \
		$(FLATC) --json $$schema; \
	done
	@echo "All schema files are valid!"

# Show help
help:
	@echo "UserCanal Swift SDK Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  all                 - Generate FlatBuffers code (default)"
	@echo "  generate-flatbuffers- Generate Swift code from .fbs schema files"
	@echo "  clean               - Remove generated files and build artifacts"
	@echo "  build               - Build the Swift package"
	@echo "  test                - Run tests"
	@echo "  install-flatc       - Install FlatBuffers compiler (macOS/Homebrew)"
	@echo "  check-flatc         - Check if FlatBuffers compiler is available"
	@echo "  validate-schema     - Validate all schema files"
	@echo "  help                - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - FlatBuffers compiler (flatc)"
	@echo "  - Swift 5.9+"
	@echo ""
	@echo "Usage:"
	@echo "  make                # Generate FlatBuffers code"
	@echo "  make test           # Run tests with fresh generated code"
	@echo "  make clean build    # Clean rebuild"

# Generate documentation
docs: generate-flatbuffers
	swift package generate-documentation

# Format Swift code (requires swift-format)
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		find Sources Tests -name "*.swift" | xargs swift-format -i; \
		echo "Code formatted successfully"; \
	else \
		echo "swift-format not found. Install with: brew install swift-format"; \
	fi

# Lint Swift code (requires SwiftLint)
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not found. Install with: brew install swiftlint"; \
	fi

# Continuous integration target
ci: check-flatc validate-schema generate-flatbuffers build test

# Development setup
setup: install-flatc generate-flatbuffers
	@echo "Development environment setup complete!"
	@echo "You can now run 'swift build' and 'swift test'"