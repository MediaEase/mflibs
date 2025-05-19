#!/usr/bin/env bash
# file: tests/test_dir.sh

source "$(dirname "${BASH_SOURCE[0]}")/../src/libs/dir.sh"

# Global variables for tests
TEST_DIR="test_dir_temp"

# Cleanup before and after each test
setup() {
  # Remove test directory if it exists
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
  # Save current directory
  ORIGINAL_DIR=$(pwd)
}

teardown() {
  # Return to the original directory
  cd "$ORIGINAL_DIR" || true
  # Remove the test directory
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# Test for mflibs::dir::mkcd with a valid directory
test_dir_mkcd_valid_directory() {
  setup

  mflibs::dir::mkcd "$TEST_DIR"
  local ret_code=$?
  local current_dir=$(basename "$(pwd)")

  assert_equals 0 $ret_code "Function should return 0 for a valid directory"
  assert_equals "$TEST_DIR" "$current_dir" "Function should change into the created directory"

  teardown
}

# Test for mflibs::dir::mkcd with a nested directory
test_dir_mkcd_nested_directory() {
  setup

  local nested_dir="$TEST_DIR/nested/deep/structure"
  mflibs::dir::mkcd "$nested_dir"
  local ret_code=$?
  local current_dir=$(pwd)

  assert_equals 0 $ret_code "Function should return 0 for a nested directory"
  assert_equals "$(realpath "$ORIGINAL_DIR/$nested_dir")" "$(realpath "$current_dir")" "Function should change into the nested directory"

  teardown
}

# Test for mflibs::dir::mkcd with missing arguments
test_dir_mkcd_missing_arguments() {
  setup

  mflibs::dir::mkcd
  local ret_code=$?

  assert_equals 3 $ret_code "Function should return 3 when arguments are missing"

  teardown
}

# Test for mflibs::dir::mkcd with an existing directory
test_dir_mkcd_existing_directory() {
  setup

  # Create the directory beforehand
  mkdir -p "$TEST_DIR"
  mflibs::dir::mkcd "$TEST_DIR"
  local ret_code=$?
  local current_dir=$(basename "$(pwd)")

  assert_equals 0 $ret_code "Function should return 0 for an existing directory"
  assert_equals "$TEST_DIR" "$current_dir" "Function should change into the existing directory"

  teardown
}

# Test for mflibs::dir::mkcd with an inaccessible directory (simulated)
test_dir_mkcd_inaccessible_directory() {
  setup

  # Simulate mkdir failure by temporarily overriding the function
  mkdir() {
    return 1  # Simulate failure
  }

  mflibs::dir::mkcd "/nonexistent/path"
  local ret_code=$?

  # Restore mkdir
  unset -f mkdir

  assert_equals 1 $ret_code "Function should return 1 when mkdir fails"

  teardown
}
