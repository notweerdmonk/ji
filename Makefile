# ji - a minimal terminal action item manager

.DEFAULT_GOAL: tests

PROJECT_ROOT := $(CURDIR)

###

TOOLS_DIR := tools

TEST_TOOL := bats

TEST_TOOL_PATH := bats/bin

TEST_TOOL_PATH := $(addprefix $(PROJECT_ROOT)/$(TOOLS_DIR)/,$(TEST_TOOL_PATH))

TEST_TOOL := $(addprefix $(TEST_TOOL_PATH)/,$(TEST_TOOL))

TEST_TOOL_OPTS := --print-output-on-failure

###

TESTS_DIR := tests

TESTS := \
test_screen.bash

TESTS := $(addprefix $(PROJECT_ROOT)/$(TESTS_DIR)/,$(TESTS))

$(TESTS):
	@$(TEST_TOOL) $(TEST_TOOL_OPTS) $@

###

tests: $(TESTS)

.PHONY: $(TESTS) tests
