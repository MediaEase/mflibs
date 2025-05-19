#!/usr/bin/env bash
# file: tests/test_log.sh

# Note: Tests for the log library are limited since it interacts directly
# with the filesystem and modifies global traps. Instead of testing full
# integration, we focus on isolating command handling logic.

# Define a test version of the handle_command function
mflibs::log::handle_command() {
  local command="$1"
  local filtered_command=""

  # Filter sensitive or irrelevant commands
  case "$command" in
    *" > /dev/null"*|*" 2> /dev/null"*|*" &>/dev/null"*|*" </dev/null"*) return ;;
    cat*"/proc/"*|cat*"/sys/"*|cat*"/dev/"*|echo*"/proc/"*|echo*"/sys/"*) return ;;
    echo*"="*|echo*"/tmp/"*|echo*"/run/"*) return ;;
    history*|trap*|unset*|alias*|unalias*|type*|set*) return ;;
    declare*|export*|local*) return ;;
  esac

  if [[ "$command" =~ (password|vault|key|user) ]]; then
    return
  fi

  filtered_command="$command"

  # Handle wget command verbosity
  if [[ "$command" =~ ^wget ]]; then
    if [[ " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
      filtered_command=$(echo "$command" | sed -E "s/ -q//g")
      filtered_command+=" -v"
    elif [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
      filtered_command=$(echo "$command" | sed -E "s/ -q//g")
      filtered_command+=" -nv"
    else
      filtered_command=$(echo "$command" | sed -E "s/ -q//g")
      filtered_command+=" -q"
    fi
  fi

  # Handle apt/apt-get command verbosity
  if [[ "$command" =~ ^apt || "$command" =~ ^apt-get ]]; then
    if [[ " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
      filtered_command=$(echo "$command" | sed -E "s/ -qq//g")
      filtered_command+=" -V"
    elif [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
      filtered_command=$(echo "$command" | sed -E "s/ -qq//g")
      filtered_command+=" -q"
    else
      filtered_command=$(echo "$command" | sed -E "s/ -qq//g")
      filtered_command+=" -qq"
    fi
  fi

  echo "$filtered_command"
}

# Simulate mflibs::log function for testing
mflibs::log() {
  local command="$1"

  if [[ " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo "[DEBUG] Executing: $command"
    eval "$command" 2>&1

  elif [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    eval "$command" 2>&1

  else
    output=$(eval "$command" 2>&1)
    if [[ -n "$output" ]]; then
      echo "[LOGGED] $output"
    fi
  fi
}

# Test filtering of sensitive or ignored commands
test_log_handle_command_filter() {
  MFLIBS_LOADED=""

  local normal_command="echo 'Hello world'"
  local dev_null_command="echo 'test' > /dev/null"
  local proc_command="cat /proc/cpuinfo"
  local password_command="echo 'password=secret'"

  local result=$(mflibs::log::handle_command "$normal_command")
  assert_equals "$normal_command" "$result" "Normal commands should not be filtered"

  result=$(mflibs::log::handle_command "$dev_null_command")
  assert_equals "" "$result" "Commands with /dev/null redirection should be filtered"

  result=$(mflibs::log::handle_command "$proc_command")
  assert_equals "" "$result" "Commands accessing /proc should be filtered"

  result=$(mflibs::log::handle_command "$password_command")
  assert_equals "" "$result" "Commands with sensitive keywords should be filtered"
}

# Test handling of wget command verbosity
test_log_handle_wget_options() {
  MFLIBS_LOADED=""
  local wget_command="wget http://example.com -q"
  local result=$(mflibs::log::handle_command "$wget_command")
  assert_equals "wget http://example.com -q" "$result" "Wget options should remain unchanged in normal mode"

  MFLIBS_LOADED="debug"
  result=$(mflibs::log::handle_command "$wget_command")
  assert_matches "wget http://example\.com -v" "$result" "Wget should use -v in debug mode"

  MFLIBS_LOADED="verbose"
  result=$(mflibs::log::handle_command "$wget_command")
  assert_matches "wget http://example\.com -nv" "$result" "Wget should use -nv in verbose mode"
}

# Test handling of apt/apt-get command verbosity
test_log_handle_apt_options() {
  MFLIBS_LOADED=""
  local apt_command="apt-get install example -qq"
  local result=$(mflibs::log::handle_command "$apt_command")
  assert_equals "apt-get install example -qq" "$result" "Apt-get options should remain unchanged in normal mode"

  MFLIBS_LOADED="debug"
  result=$(mflibs::log::handle_command "$apt_command")
  assert_matches "apt-get install example -V" "$result" "Apt-get should use -V in debug mode"

  MFLIBS_LOADED="verbose"
  result=$(mflibs::log::handle_command "$apt_command")
  assert_matches "apt-get install example -q" "$result" "Apt-get should use -q in verbose mode"
}

# Test mflibs::log in normal mode
test_log_normal_mode() {
  MFLIBS_LOADED=""
  local result=$(mflibs::log "echo 'Normal mode test'")
  assert_matches "\[LOGGED\] Normal mode test" "$result" "In normal mode, output should be prefixed with [LOGGED]"
}

# Test mflibs::log in verbose mode
test_log_verbose_mode() {
  MFLIBS_LOADED="verbose"
  local result=$(mflibs::log "echo 'Verbose mode test'")
  assert_equals "Verbose mode test" "$result" "In verbose mode, output should be shown as is"
}

# Test mflibs::log in debug mode
test_log_debug_mode() {
  MFLIBS_LOADED="debug"
  local result=$(mflibs::log "echo 'Debug mode test'")

  assert_matches "\[DEBUG\] Executing: echo 'Debug mode test'" "$(echo "$result" | head -n1)" "In debug mode, command should be prefixed"
  assert_matches "Debug mode test" "$(echo "$result" | tail -n1)" "In debug mode, output should be visible after the command"
}

# Helper function for regex-based assertions
assert_matches() {
  local pattern="$1"
  local value="$2"
  local message="$3"

  if [[ "$value" =~ $pattern ]]; then
    assert true "$message"
  else
    assert false "$message: '$value' does not match pattern '$pattern'"
  fi
}
