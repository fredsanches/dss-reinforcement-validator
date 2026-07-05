CC := /usr/bin/clang
CFLAGS := -std=c17 -g -Wall -Wextra -Wpedantic -Wconversion -Wshadow -O0
CPPFLAGS := -Iinclude -Itests
SANITIZE_FLAGS := -fsanitize=address -fno-omit-frame-pointer

BUILD_DIR := build
SRC := src/model.c src/config.c src/validation.c src/csv.c src/report.c
APP_SRC := src/main.c

# These create make variables (compiled test executables) and not directories!
TEST_BINS := \
	$(BUILD_DIR)/test_smoke \
	$(BUILD_DIR)/test_model \
	$(BUILD_DIR)/test_validation \
	$(BUILD_DIR)/test_config \
	$(BUILD_DIR)/test_csv \
	$(BUILD_DIR)/test_report

.PHONY: all test sanitize clean

all: $(BUILD_DIR)/gridval

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/gridval: $(SRC) $(APP_SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(SRC) $(APP_SRC) -o $@

$(BUILD_DIR)/test_smoke: tests/test_smoke.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_smoke.c -o $@

$(BUILD_DIR)/test_model: tests/test_model.c src/model.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_model.c src/model.c -o $@

$(BUILD_DIR)/test_validation: tests/test_validation.c src/model.c src/validation.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_validation.c src/model.c src/validation.c -o $@

$(BUILD_DIR)/test_config: tests/test_config.c src/config.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_config.c src/config.c -o $@

$(BUILD_DIR)/test_csv: tests/test_csv.c src/model.c src/csv.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_csv.c src/model.c src/csv.c -o $@

$(BUILD_DIR)/test_report: tests/test_report.c src/model.c src/report.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) tests/test_report.c src/model.c src/report.c -o $@

test: $(TEST_BINS)
	$(BUILD_DIR)/test_smoke
	$(BUILD_DIR)/test_model
	$(BUILD_DIR)/test_validation
	$(BUILD_DIR)/test_config
	$(BUILD_DIR)/test_csv
	$(BUILD_DIR)/test_report

clean:
	rm -rf $(BUILD_DIR)