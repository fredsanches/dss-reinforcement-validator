CC := clang
CFLAGS := -std=c17 -g -Wall -Wextra -Wpedantic -Wconversion -Wshadow -O0
CPPFLAGS := -Iinclude -Itests
SANITIZE_FLAGS := -fsanitize=address -fno-omit-frame-pointer

BUILD_DIR := build
SRC := src/model.c
APP_SRC := src/main.c

ifeq ($(OS),Windows_NT)
	EXE := .exe
	MKDIR_BUILD 	:= if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	REMOVE_BUILD 	:= if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
else
	EXE :=
	MKDIR_BUILD		:= mkdir -p "$(BUILD_DIR)"
	REMOVE_BUILD	:= rm -rf "$(BUILD_DIR)"
endif

# These create make variables (compiled test executables) and not directories!
TEST_BINS := \
	$(BUILD_DIR)/test_smoke$(EXE) \
	$(BUILD_DIR)/test_model$(EXE)

.PHONY: all test clean

all: $(TEST_BINS)

$(BUILD_DIR):
	$(MKDIR_BUILD)

# `$<` means the first prerequisite
# -fsyntax-only checks preprocessing, syntax, types, declarations and warnings
check-%: src/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -fsyntax-only $<

$(BUILD_DIR)/gridval$(EXE): $(SRC) $(APP_SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(SRC) $(APP_SRC) -o $@

$(BUILD_DIR)/test_smoke$(EXE): tests/test_smoke.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_smoke.c -o $@

# Only .c files are passed to clang. Headers are prerequisites and they are not independant implementation files.
$(BUILD_DIR)/test_model$(EXE): \
	tests/test_model.c \
	tests/test_helpers.h \
	src/model.c \
	include/gridval/model.h \
	| $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_model.c src/model.c -o $@ 

test: $(TEST_BINS)
	$(BUILD_DIR)/test_smoke$(EXE)
	$(BUILD_DIR)/test_model$(EXE)

clean:
	$(REMOVE_BUILD)