#!/usr/bin/env bash
# file: tests/test_file.sh

source "$(dirname "${BASH_SOURCE[0]}")/../src/libs/file.sh"

# Global variables for test paths
TEST_DIR="$(dirname "${BASH_SOURCE[0]}")/tmp_test_file"
TEST_SOURCE_FILE="$TEST_DIR/source_file.txt"
TEST_DEST_DIR="$TEST_DIR/dest"
TEST_DEST_FILE="$TEST_DEST_DIR/dest_file.txt"
TEST_ARCHIVE_DIR="$TEST_DIR/archive"
TEST_ARCHIVE_FILE="test_archive.tar.gz"
TEST_YAML_FILE="$TEST_DIR/test_config.yaml"

# Setup and teardown
setup() {
  # Clean test directory if it exists
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
  mkdir -p "$TEST_DIR" "$TEST_DEST_DIR" "$TEST_ARCHIVE_DIR"
  echo "Test content" > "$TEST_SOURCE_FILE"
  
  cat > "$TEST_YAML_FILE" << 'EOF'
arguments:
  app_name: "test_app"
  details:
    github: "https://github.com/test/repo"
  paths:
    - backup: "/path/to/backup"
    - data: "/path/to/data"
EOF
}

teardown() {
  [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Tests for mflibs::file::copy
test_file_copy_valid() {
  setup

  mflibs::file::copy "$TEST_SOURCE_FILE" "$TEST_DEST_FILE"
  local ret_code=$?
  
  assert_equals 0 $ret_code "Should return 0 for a successful copy"
  assert "[ -f \"$TEST_DEST_FILE\" ]" "Destination file should exist"
  assert "grep -q \"Test content\" \"$TEST_DEST_FILE\"" "Destination file content should match"

  teardown
}

test_file_copy_missing_arguments() {
  setup
  mflibs::file::copy
  local ret_code=$?
  assert_equals 2 $ret_code "Should return 2 when arguments are missing"
  teardown
}

test_file_copy_nonexistent_source() {
  setup
  mflibs::file::copy "$TEST_DIR/nonexistent_file.txt" "$TEST_DEST_FILE"
  local ret_code=$?
  assert_equals 3 $ret_code "Should return 3 when source does not exist"
  assert "[ ! -f \"$TEST_DEST_FILE\" ]" "Destination file should not be created"
  teardown
}

# Tests for mflibs::file::move
test_file_move_valid() {
  setup
  mflibs::file::move "$TEST_SOURCE_FILE" "$TEST_DEST_FILE"
  local ret_code=$?
  assert_equals 0 $ret_code "Should return 0 for a successful move"
  assert "[ -f \"$TEST_DEST_FILE\" ]" "Destination file should exist"
  assert "[ ! -f \"$TEST_SOURCE_FILE\" ]" "Source file should no longer exist"
  assert "grep -q \"Test content\" \"$TEST_DEST_FILE\"" "Moved file content should match"
  teardown
}

test_file_move_missing_arguments() {
  setup
  mflibs::file::move
  local ret_code=$?
  assert_equals 2 $ret_code "Should return 2 when arguments are missing"
  teardown
}

test_file_move_nonexistent_source() {
  setup
  mflibs::file::move "$TEST_DIR/nonexistent_file.txt" "$TEST_DEST_FILE"
  local ret_code=$?
  assert_equals 3 $ret_code "Should return 3 when source does not exist"
  assert "[ ! -f \"$TEST_DEST_FILE\" ]" "Destination file should not be created"
  teardown
}

# Tests for mflibs::file::inflate
test_file_inflate_valid() {
  setup
  mflibs::file::inflate "$TEST_SOURCE_FILE" "$TEST_ARCHIVE_FILE" "$TEST_ARCHIVE_DIR"
  local ret_code=$?
  assert_equals 0 $ret_code "Should return 0 for a valid archive"
  assert "[ -f \"$TEST_ARCHIVE_DIR/$TEST_ARCHIVE_FILE\" ]" "Archive file should exist"
  teardown
}

test_file_inflate_missing_arguments() {
  setup
  mflibs::file::inflate
  local ret_code=$?
  assert_equals 2 $ret_code "Should return 2 when arguments are missing"
  teardown
}

test_file_inflate_nonexistent_source() {
  setup
  mflibs::file::inflate "$TEST_DIR/nonexistent_file.txt" "$TEST_ARCHIVE_FILE" "$TEST_ARCHIVE_DIR"
  local ret_code=$?
  assert_equals 3 $ret_code "Should return 3 when source does not exist"
  assert "[ ! -f \"$TEST_ARCHIVE_DIR/$TEST_ARCHIVE_FILE\" ]" "Archive file should not be created"
  teardown
}

# Tests for mflibs::file::yaml::key_load
test_file_yaml_key_load() {
  setup
  local app_name=$(mflibs::file::yaml::key_load "$TEST_YAML_FILE" "app_name")
  assert_equals "test_app" "$app_name" "Should correctly load top-level key"

  local github=$(mflibs::file::yaml::key_load "$TEST_YAML_FILE" "details.github")
  assert_equals "https://github.com/test/repo" "$github" "Should correctly load nested key"

  local backup=$(mflibs::file::yaml::key_load "$TEST_YAML_FILE" "paths.[].backup")
  assert_equals "/path/to/backup" "$backup" "Should correctly load key inside array"

  teardown
}

# Tests for mflibs::file::yaml::key_exists
test_file_yaml_key_exists() {
  setup
  mflibs::file::yaml::key_exists "$TEST_YAML_FILE" "app_name"
  assert_equals 0 $? "Should return 0 when key exists"

  mflibs::file::yaml::key_exists "$TEST_YAML_FILE" "nonexistent_key"
  assert_equals 1 $? "Should return 1 when key does not exist"

  teardown
}

# Tests for mflibs::file::extract (return code only)
test_file_extract() {
  setup

  mflibs::file::extract
  local ret_code=$?
  assert_equals 2 $ret_code "Should return 2 when arguments are missing"

  mflibs::file::extract "nonexistent.tar.gz"
  ret_code=$?
  assert_equals 3 $ret_code "Should return 3 when file does not exist"

  touch "$TEST_DIR/test.unknown"
  mflibs::file::extract "$TEST_DIR/test.unknown"
  ret_code=$?
  assert_equals 1 $ret_code "Should return 1 for unknown file extension"

  teardown
}
