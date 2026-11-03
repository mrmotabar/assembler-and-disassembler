# ==============================================================================
# Makefile: NASM x86_64 Assembler & Disassembler
# ==============================================================================

NASM         ?= nasm
LD           ?= ld
PYTHON       ?= python3

SRC_DIR      := src
COMMON_DIR   := src/common
BUILD_DIR    := build
DOCKER_IMAGE := codeneomatrix/nasm

ASSEMBLER_BIN    := $(BUILD_DIR)/assembler
DISASSEMBLER_BIN := $(BUILD_DIR)/disassembler

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Detect if Docker is required (macOS Apple Silicon or non-x86_64 host)
USE_DOCKER ?= $(shell if [ "$(UNAME_S)" = "Linux" ] && [ "$(UNAME_M)" = "x86_64" ]; then echo 0; else echo 1; fi)

.PHONY: all build build-assembler build-disassembler test clean help

all: build

build: build-assembler build-disassembler

build-assembler: $(ASSEMBLER_BIN)

build-disassembler: $(DISASSEMBLER_BIN)

$(ASSEMBLER_BIN): $(SRC_DIR)/assembler.asm $(COMMON_DIR)/system-constants.asm $(COMMON_DIR)/console-io.asm
	@mkdir -p $(BUILD_DIR)
ifeq ($(USE_DOCKER),1)
	@echo "==> Building assembler binary with Docker ($(DOCKER_IMAGE))..."
	docker run --rm -v "$(CURDIR):/app" -w /app $(DOCKER_IMAGE) sh -c \
		"mkdir -p $(BUILD_DIR) && \
		 $(NASM) -f elf64 -I$(COMMON_DIR)/ $(SRC_DIR)/assembler.asm -o $(BUILD_DIR)/assembler.o && \
		 $(LD) $(BUILD_DIR)/assembler.o -o $(ASSEMBLER_BIN)"
else
	@echo "==> Building assembler binary natively..."
	$(NASM) -f elf64 -I$(COMMON_DIR)/ $(SRC_DIR)/assembler.asm -o $(BUILD_DIR)/assembler.o
	$(LD) $(BUILD_DIR)/assembler.o -o $(ASSEMBLER_BIN)
endif
	@echo "==> Assembler binary built: $(ASSEMBLER_BIN)"

$(DISASSEMBLER_BIN): $(SRC_DIR)/disassembler.asm $(COMMON_DIR)/system-constants.asm $(COMMON_DIR)/console-io.asm
	@mkdir -p $(BUILD_DIR)
ifeq ($(USE_DOCKER),1)
	@echo "==> Building disassembler binary with Docker ($(DOCKER_IMAGE))..."
	docker run --rm -v "$(CURDIR):/app" -w /app $(DOCKER_IMAGE) sh -c \
		"mkdir -p $(BUILD_DIR) && \
		 $(NASM) -f elf64 -I$(COMMON_DIR)/ $(SRC_DIR)/disassembler.asm -o $(BUILD_DIR)/disassembler.o && \
		 $(LD) $(BUILD_DIR)/disassembler.o -o $(DISASSEMBLER_BIN)"
else
	@echo "==> Building disassembler binary natively..."
	$(NASM) -f elf64 -I$(COMMON_DIR)/ $(SRC_DIR)/disassembler.asm -o $(BUILD_DIR)/disassembler.o
	$(LD) $(BUILD_DIR)/disassembler.o -o $(DISASSEMBLER_BIN)
endif
	@echo "==> Disassembler binary built: $(DISASSEMBLER_BIN)"

# Verify NASM syntax natively without linking
verify-asm:
	@echo "==> Verifying NASM assembly syntax natively..."
	$(NASM) -f elf64 -I$(COMMON_DIR)/ $(SRC_DIR)/assembler.asm -o /dev/null
	$(NASM) -f elf64 -I$(COMMON_DIR)/ $(SRC_DIR)/disassembler.asm -o /dev/null
	@echo "==> Assembly syntax verification passed!"

test:
	@echo "==> Running automated test suite..."
	@./scripts/run-tests.sh

clean:
	@echo "==> Cleaning build artifacts and temporary files..."
	rm -rf $(BUILD_DIR) *.o src/*.o first-file.txt second-file.txt .pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "==> Clean complete."

help:
	@echo "NASM x86_64 Assembler & Disassembler Build System"
	@echo ""
	@echo "Available Targets:"
	@echo "  make build               - Build both assembler and disassembler ELF64 binaries"
	@echo "  make build-assembler     - Build assembler binary ($(ASSEMBLER_BIN))"
	@echo "  make build-disassembler  - Build disassembler binary ($(DISASSEMBLER_BIN))"
	@echo "  make verify-asm          - Verify NASM assembly syntax natively with nasm"
	@echo "  make test                - Run automated correctness test suite"
	@echo "  make clean               - Remove build artifacts and temporary files"
	@echo "  make help                - Display this help message"
