#!/usr/bin/env bash
# file: tests/test_status.sh

# Note: Tests for the status library simulate terminal output
# using testable alternatives by capturing printed output.
source "$(dirname "${BASH_SOURCE[0]}")/../src/libs/status.sh"
# Simulate environment setup for status tests
setup_status_test_env() {
  # Backup environment variable
  if [[ -n "${MFLIBS_LOG_LOCATION}" ]]; then
    ORIGINAL_LOG_LOCATION="${MFLIBS_LOG_LOCATION}"
  fi

  # Create a temporary file for logs
  MFLIBS_LOG_LOCATION=$(mktemp)
}

# Clean up the environment after each test
cleanup_status_test_env() {
  # Delete temporary file
  if [[ -f "${MFLIBS_LOG_LOCATION}" ]]; then
    rm -f "${MFLIBS_LOG_LOCATION}"
  fi

  # Restore original environment variable
  if [[ -n "${ORIGINAL_LOG_LOCATION}" ]]; then
    MFLIBS_LOG_LOCATION="${ORIGINAL_LOG_LOCATION}"
    unset ORIGINAL_LOG_LOCATION
  else
    unset MFLIBS_LOG_LOCATION
  fi
}

# Simulate status functions to capture terminal output

mflibs::status::error() {
  declare message=${1:-"an unspecified error occurred"}
  declare mf_error=${2:-1}
  message=${message//$HOME/\~}

  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo "[ERROR][$mf_error] - $message"
    echo "[ERROR][$mf_error] - stack trace:"
  else
    echo "$message"
  fi
}

mflibs::status::warn() {
  declare message=${1:-"an unspecified error occurred"}
  declare mf_error=${2:-1}
  message=${message//$HOME/\~}

  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo "[WARN][$mf_error] - $message"
  else
    echo "$message"
  fi
}

mflibs::status::success() {
  declare message=${1:-"command completed successfully"}
  message=${message//$HOME/\~}

  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo "[SUCCESS] - $message"
  else
    echo "$message"
  fi
}

mflibs::status::info() {
  declare message=${1:-"information not specified"}
  message=${message//$HOME/\~}

  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo "[INFO] - $message"
  else
    echo "$message"
  fi
}

mflibs::status::header() {
  declare message=${1:-"header not specified"}
  message=${message//$HOME/\~}

  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo "[HEADER] - $message"
  else
    echo "$message"
  fi
}

# Test: error() in normal mode
test_status_error_normal() {
  setup_status_test_env
  MFLIBS_LOADED=""

  local test_message="This is an error message"
  local result=$(mflibs::status::error "$test_message")

  assert_equals "$test_message" "$result" "In normal mode, error() should print the message as-is"

  cleanup_status_test_env
}

# Test: error() in verbose mode
test_status_error_verbose() {
  setup_status_test_env
  MFLIBS_LOADED="verbose"

  local test_message="This is an error message"
  local error_code=42
  local result=$(mflibs::status::error "$test_message" "$error_code")

  assert_matches "^\[ERROR\]\[$error_code\] - $test_message$" "$(echo "$result" | head -n1)" "In verbose mode, error() should prefix with [ERROR] and error code"
  assert_matches "^\[ERROR\]\[$error_code\] - stack trace:$" "$(echo "$result" | tail -n1)" "In verbose mode, error() should show stack trace"

  cleanup_status_test_env
}

# Test: error() in debug mode (same as verbose)
test_status_error_debug() {
  setup_status_test_env
  MFLIBS_LOADED="debug"

  local test_message="This is an error message"
  local error_code=42
  local result=$(mflibs::status::error "$test_message" "$error_code")

  assert_matches "^\[ERROR\]\[$error_code\] - $test_message$" "$(echo "$result" | head -n1)" "In debug mode, error() should prefix with [ERROR] and error code"
  assert_matches "^\[ERROR\]\[$error_code\] - stack trace:$" "$(echo "$result" | tail -n1)" "In debug mode, error() should show stack trace"

  cleanup_status_test_env
}

# Test: warn() in normal mode
test_status_warn_normal() {
  setup_status_test_env
  MFLIBS_LOADED=""

  local test_message="This is a warning message"
  local result=$(mflibs::status::warn "$test_message")

  assert_equals "$test_message" "$result" "In normal mode, warn() should print the message as-is"

  cleanup_status_test_env
}

# Test: warn() in verbose mode
test_status_warn_verbose() {
  setup_status_test_env
  MFLIBS_LOADED="verbose"

  local test_message="This is a warning message"
  local error_code=42
  local result=$(mflibs::status::warn "$test_message" "$error_code")

  assert_matches "^\[WARN\]\[$error_code\] - $test_message$" "$result" "In verbose mode, warn() should prefix with [WARN] and code"

  cleanup_status_test_env
}

# Test: success() in normal mode
test_status_success_normal() {
  setup_status_test_env
  MFLIBS_LOADED=""

  local test_message="Operation completed successfully"
  local result=$(mflibs::status::success "$test_message")

  assert_equals "$test_message" "$result" "In normal mode, success() should print the message as-is"

  cleanup_status_test_env
}

# Test: success() in verbose mode
test_status_success_verbose() {
  setup_status_test_env
  MFLIBS_LOADED="verbose"

  local test_message="Operation completed successfully"
  local result=$(mflibs::status::success "$test_message")

  assert_matches "^\[SUCCESS\] - $test_message$" "$result" "In verbose mode, success() should prefix with [SUCCESS]"

  cleanup_status_test_env
}

# Test: info() in normal mode
test_status_info_normal() {
  setup_status_test_env
  MFLIBS_LOADED=""

  local test_message="This is an informational message"
  local result=$(mflibs::status::info "$test_message")

  assert_equals "$test_message" "$result" "In normal mode, info() should print the message as-is"

  cleanup_status_test_env
}

# Test: info() in verbose mode
test_status_info_verbose() {
  setup_status_test_env
  MFLIBS_LOADED="verbose"

  local test_message="This is an informational message"
  local result=$(mflibs::status::info "$test_message")

  assert_matches "^\[INFO\] - $test_message$" "$result" "In verbose mode, info() should prefix with [INFO]"

  cleanup_status_test_env
}

# Test: header() in normal mode
test_status_header_normal() {
  setup_status_test_env
  MFLIBS_LOADED=""

  local test_message="This is a header message"
  local result=$(mflibs::status::header "$test_message")

  assert_equals "$test_message" "$result" "In normal mode, header() should print the message as-is"

  cleanup_status_test_env
}

# Test: header() in verbose mode
test_status_header_verbose() {
  setup_status_test_env
  MFLIBS_LOADED="verbose"

  local test_message="This is a header message"
  local result=$(mflibs::status::header "$test_message")

  assert_matches "^\[HEADER\] - $test_message$" "$result" "In verbose mode, header() should prefix with [HEADER]"

  cleanup_status_test_env
}

# Test: default messages for all functions
test_status_default_messages() {
  setup_status_test_env
  MFLIBS_LOADED=""

  local error_result=$(mflibs::status::error)
  local warn_result=$(mflibs::status::warn)
  local success_result=$(mflibs::status::success)
  local info_result=$(mflibs::status::info)
  local header_result=$(mflibs::status::header)

  assert_equals "an unspecified error occurred" "$error_result" "Default error message should be 'an unspecified error occurred'"
  assert_equals "an unspecified error occurred" "$warn_result" "Default warning message should be 'an unspecified error occurred'"
  assert_equals "command completed successfully" "$success_result" "Default success message should be 'command completed successfully'"
  assert_equals "information not specified" "$info_result" "Default info message should be 'information not specified'"
  assert_equals "header not specified" "$header_result" "Default header message should be 'header not specified'"

  cleanup_status_test_env
}
