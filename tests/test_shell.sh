#!/usr/bin/env bash
# file: tests/test_shell.sh

# Note: Tests for the shell.sh library validate the functionality of text formatting 
# and shell output functions

# Setup function
setup() {
  if [[ -n "${MFLIBS_LOADED}" ]]; then
    ORIGINAL_MFLIBS_LOADED=("${MFLIBS_LOADED[@]}")
  fi
  
  # Create a clean environment
  unset MFLIBS_LOADED
  declare -ga MFLIBS_LOADED=()
  source "$(dirname "${BASH_SOURCE[0]}")/../src/libs/shell.sh"
}

# Teardown function
teardown() {
  # Restore original environment variables
  if [[ -n "${ORIGINAL_MFLIBS_LOADED}" ]]; then
    MFLIBS_LOADED=("${ORIGINAL_MFLIBS_LOADED[@]}")
    unset ORIGINAL_MFLIBS_LOADED
  else
    unset MFLIBS_LOADED
  fi
}

# Test basic text output
test_shell_basic_text() {
  setup
  
  local output
  
  # Test standard text output
  output=$(mflibs::shell::text "test message")
  assert "true" "Basic text output should work"
  
  # Test newline function
  output=$(mflibs::shell::misc::nl)
  assert "true" "Newline function should work"
  
  # Test single line output
  output=$(mflibs::shell::text::sl "test message")
  assert "[[ \"$output\" != *$'\n'* ]]" "Single line output should not contain newline"
  
  teardown
}

# Test all color functions
test_shell_color_functions() {
  setup
  
  local output
  local colors=("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white")
  
  # Test each color
  for color in "${colors[@]}"; do
    # Test normal color
    output=$(mflibs::shell::text::$color "test message")
    assert "true" "$color text output should work"
    
    # Test single line version
    output=$(mflibs::shell::text::${color}::sl "test message")
    assert "[[ \"$output\" != *$'\n'* ]]" "$color single line output should not contain newline"
    
    # Test bold color
    output=$(mflibs::shell::text::${color}::bold "test message")
    assert "true" "$color bold text output should work"
    
    # Test bold single line
    output=$(mflibs::shell::text::${color}::bold::sl "test message")
    assert "[[ \"$output\" != *$'\n'* ]]" "$color bold single line output should not contain newline"
    
    # Test underline color
    output=$(mflibs::shell::text::${color}::underline "test message")
    assert "true" "$color underline text output should work"
    
    # Test underline single line
    output=$(mflibs::shell::text::${color}::underline::sl "test message")
    assert "[[ \"$output\" != *$'\n'* ]]" "$color underline single line output should not contain newline"
    
    # Test standout color
    output=$(mflibs::shell::text::${color}::standout "test message")
    assert "true" "$color standout text output should work"
    
    # Test standout single line
    output=$(mflibs::shell::text::${color}::standout::sl "test message")
    assert "[[ \"$output\" != *$'\n'* ]]" "$color standout single line output should not contain newline"
  done
  
  teardown
}

# Test text formatting functions
test_shell_text_formatting() {
  setup
  
  local output
  local formats=("bold" "underline" "standout")
  
  # Test each formatting option
  for format in "${formats[@]}"; do
    # Test format
    output=$(mflibs::shell::text::$format "test message")
    assert "true" "$format text output should work"
    
    # Test single line format
    output=$(mflibs::shell::text::${format}::sl "test message")
    assert "[[ \"$output\" != *$'\n'* ]]" "$format single line output should not contain newline"
  done
  
  teardown
}

# Test icon display functions
test_shell_icons() {
  setup
  
  local output
  local icons=("arrow" "warning" "check" "cross" "chevron")
  local colors=("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white")
  
  # Test each icon
  for icon in "${icons[@]}"; do
    # Test plain icon
    output=$(mflibs::shell::icon::$icon "test message")
    assert "true" "$icon output should work"
    
    # Test colored icons
    for color in "${colors[@]}"; do
      output=$(mflibs::shell::icon::${icon}::$color "test message")
      assert "true" "$icon with $color should work"
    done
  done
  
  teardown
}

# Test background color functions
test_shell_background_colors() {
  setup
  
  local output
  local colors=("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white")
  
  # Test each background color
  for color in "${colors[@]}"; do
    mflibs::shell::background::$color
    output=$(mflibs::shell::text "test message")
    assert "true" "Background $color should work"
  done
  
  teardown
}
