CC := /usr/bin/clang
CFLAGS := -std=c17 -g -Wall -Wextra -Wpedantic -Wconversion -Wshadow -O0
SANITIZE_FLAGS := -fsanitize=address -fno-omit-frame-pointer

BUILD_DIR := build
TEST_TARGET := $(BUILD_DIR)/test_smoke
TEST_SOURCE := tests/test_smoke.c

.PHONY: all test sanitize clean

all: $(TEST_TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TEST_TARGET): $(TEST_SOURCE) tests/test_helpers.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(TEST_SOURCE) -o $(TEST_TARGET)

test: $(TEST_TARGET)
	./$(TEST_TARGET)

sanitize: $(TEST_SOURCE) tests/test_helpers.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SANITIZE_FLAGS) $(TEST_SOURCE) -o $(BUILD_DIR)/test_smoke_sanitize
	./$(BUILD_DIR)/test_smoke_sanitize

clean:
	rm -rf $(BUILD_DIR)