#!/usr/bin/env bash
# file: tests/test_init.sh

# Note: Tests for the init.sh library validate the functionality of 
# the initialization and library importing functions.

# Setup function to prepare environment for tests
setup() {
  # Save original environment variables if they exist
  if [[ -n "${MFLIBS_LOADED}" ]]; then
    ORIGINAL_MFLIBS_LOADED=("${MFLIBS_LOADED[@]}")
  fi
  
  # Create a clean environment
  unset MFLIBS_LOADED
  declare -ga MFLIBS_LOADED=()
  
  # Remember the current directory
  CURRENT_DIR="$(pwd)"
}

# Teardown function to clean up after tests
teardown() {
  # Restore original environment variables
  if [[ -n "${ORIGINAL_MFLIBS_LOADED}" ]]; then
    MFLIBS_LOADED=("${ORIGINAL_MFLIBS_LOADED[@]}")
    unset ORIGINAL_MFLIBS_LOADED
  else
    unset MFLIBS_LOADED
  fi
  
  # Return to the original directory
  cd "$CURRENT_DIR" || return
}

# Test the environment initialization function
test_environment_init() {
  setup
  
  # Source init.sh to access the functions
  source "$(dirname "${BASH_SOURCE[0]}")/../src/init.sh"
  
  # Test that required global variables are set
  assert "[ -n \"$mflibs_lib_location\" ]" "mflibs_lib_location should be set after initialization"
  assert "[ -n \"$mflibs_custom_location\" ]" "mflibs_custom_location should be set after initialization"
  
  # Test that the paths are correct
  local expected_lib_path
  expected_lib_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/../src/libs" && pwd)"
  assert_equals "$expected_lib_path" "$mflibs_lib_location" "mflibs_lib_location should point to the libs directory"
  
  local expected_custom_path
  expected_custom_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/../src/custom" && pwd)"
  assert_equals "$expected_custom_path" "$mflibs_custom_location" "mflibs_custom_location should point to the custom directory"
  
  teardown
}

# Create mock libraries for testing
create_mock_libraries() {
  local test_dir="$1"
  
  # Create mock library directories
  mkdir -p "$test_dir/libs"
  mkdir -p "$test_dir/custom"
  
  # Create mock standard library
  cat > "$test_dir/libs/test_lib.sh" << 'EOF'
#!/usr/bin/env bash
test_lib_function() {
  echo "test_lib_function called"
  return 0
}
MFLIBS_LOADED+=("test_lib")
EOF

  # Create mock custom library
  cat > "$test_dir/custom/test_custom.sh" << 'EOF'
#!/usr/bin/env bash
test_custom_function() {
  echo "test_custom_function called"
  return 0
}
declare -ga MFLIBS_LOADED+=("test_custom")
EOF

  # Make them executable
  chmod +x "$test_dir/libs/test_lib.sh"
  chmod +x "$test_dir/custom/test_custom.sh"
}

# Create a mock init.sh that doesn't check bash version
create_mock_init() {
  local test_dir="$1"
  
  cat > "$test_dir/init.sh" << 'EOF'
#!/usr/bin/env bash

# Initialize MFLIBS_LOADED as a global array if it doesn't exist
if [[ -z "${MFLIBS_LOADED+x}" ]]; then
  declare -ga MFLIBS_LOADED=()
fi

mflibs::environment::init() {
    declare mflibs_base_location
    declare -g mflibs_lib_location mflibs_custom_location
    mflibs_base_location="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
    mflibs_lib_location="${mflibs_base_location}/libs"
    mflibs_custom_location="${mflibs_base_location}/custom"
}

mflibs::import() {
    local loaded_libraries=()
    local failed_libraries=()
    [[ $* =~ "verbose" ]] && declare -xga MFLIBS_LOADED+=("verbose") && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - verbosity enabled\n"

    for l in ${@//,/ }; do
        [[ "$l" == "verbose" ]] && continue
        local library_path=""
        if [[ -f ${mflibs_lib_location}/${l}.sh ]]; then
            library_path="${mflibs_lib_location}/${l}.sh"
        elif [[ -f ${mflibs_custom_location}/${l}.sh ]]; then
            library_path="${mflibs_custom_location}/${l}.sh"
        fi

        if [[ -n $library_path ]]; then
            . "$library_path"
            loaded_libraries+=("$l")
        else
            failed_libraries+=("$l")
        fi
    done
    if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && [[ ${#loaded_libraries[@]} -gt 0 ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 2)SUCCESS$(tput sgr0)] - loaded libraries: ${loaded_libraries[*]}\n"
    fi
    if [[ ${#failed_libraries[@]} -gt 0 ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 3)WARN$(tput sgr0)] - libraries not loaded: ${failed_libraries[*]}\n" >&2
    fi
    if [[ " ${loaded_libraries[*]} " =~ log ]]; then
        [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - logging to ${MFLIBS_LOG_LOCATION}\n"
    fi
}

mflibs::environment::init
EOF

  chmod +x "$test_dir/init.sh"
}

# Test the import function with a standard library
test_import_standard_library() {
  setup
  
  # Create a temporary test directory
  local test_dir
  test_dir="$(mktemp -d)"
  
  # Create mock libraries and init
  create_mock_libraries "$test_dir"
  create_mock_init "$test_dir"
  
  # Change to the test directory
  cd "$test_dir" || return
  
  # Source the mock init.sh
  source "./init.sh"
  
  # Import the test standard library
  mflibs::import "test_lib"
  
  # Verify the library was loaded
  assert "type -t test_lib_function &>/dev/null" "Standard library function should be available after import"
  assert "[[ \" \${MFLIBS_LOADED[*]} \" =~ test_lib ]]" "MFLIBS_LOADED should contain the imported library"
  
  # Clean up
  rm -rf "$test_dir"
  teardown
}

# Test the import function with a custom library
test_import_custom_library() {
  setup
  
  # Create a temporary test directory
  local test_dir
  test_dir="$(mktemp -d)"
  
  # Create mock libraries and init
  create_mock_libraries "$test_dir"
  create_mock_init "$test_dir"
  
  # Change to the test directory
  cd "$test_dir" || return
  
  # Source the mock init.sh
  source "./init.sh"
  
  # Import the test custom library
  mflibs::import "test_custom"
  
  # Verify the library was loaded
  assert "type -t test_custom_function &>/dev/null" "Custom library function should be available after import"
  assert "[[ \" \${MFLIBS_LOADED[*]} \" =~ test_custom ]]" "MFLIBS_LOADED should contain the imported custom library"
  
  # Clean up
  rm -rf "$test_dir"
  teardown
}

# Test importing multiple libraries at once
test_import_multiple_libraries() {
  setup
  
  # Create a temporary test directory
  local test_dir
  test_dir="$(mktemp -d)"
  
  # Create mock libraries and init
  create_mock_libraries "$test_dir"
  create_mock_init "$test_dir"
  
  # Change to the test directory
  cd "$test_dir" || return
  
  # Source the mock init.sh
  source "./init.sh"
  
  # Import multiple libraries using comma syntax
  mflibs::import "test_lib,test_custom"
  
  # Verify both libraries were loaded
  assert "type -t test_lib_function &>/dev/null" "Standard library function should be available after import"
  assert "type -t test_custom_function &>/dev/null" "Custom library function should be available after import"
  assert "[[ \" \${MFLIBS_LOADED[*]} \" =~ test_lib ]]" "MFLIBS_LOADED should contain the imported standard library"
  assert "[[ \" \${MFLIBS_LOADED[*]} \" =~ test_custom ]]" "MFLIBS_LOADED should contain the imported custom library"
  
  # Clean up
  rm -rf "$test_dir"
  teardown
}

# Test importing a non-existent library
test_import_nonexistent_library() {
  setup
  
  # Create a temporary test directory
  local test_dir
  test_dir="$(mktemp -d)"
  
  # Create mock libraries and init
  create_mock_libraries "$test_dir"
  create_mock_init "$test_dir"
  
  # Change to the test directory
  cd "$test_dir" || return
  
  # Source the mock init.sh
  source "./init.sh"
  
  # Capture the standard error output
  local stderr
  stderr=$(mflibs::import "nonexistent_lib" 2>&1)
  
  # Verify the warning message contains the library name
  assert "[[ \"$stderr\" == *\"nonexistent_lib\"* ]]" "Warning should mention the non-existent library"
  
  # Verify the function didn't crash
  assert_equals 0 $? "Import function should not fail when a library is not found"
  
  # Clean up
  rm -rf "$test_dir"
  teardown
}

# Test the verbose mode
test_import_verbose_mode() {
  setup
  
  # Create a temporary test directory
  local test_dir
  test_dir="$(mktemp -d)"
  
  # Create mock libraries and init
  create_mock_libraries "$test_dir"
  create_mock_init "$test_dir"
  
  # Change to the test directory
  cd "$test_dir" || return
  
  # Source the mock init.sh
  source "./init.sh"
  
  # Make sure MFLIBS_LOADED is an array
  if [[ -z "${MFLIBS_LOADED+x}" ]]; then
    declare -ga MFLIBS_LOADED=()
  fi
  
  # Exécuter d'abord la commande pour modifier MFLIBS_LOADED
  mflibs::import "test_lib" "verbose" > /tmp/stdout_output 2>/dev/null
  
  # Puis lire la sortie ensuite
  local stdout
  stdout=$(<"/tmp/stdout_output")
    
  # Verify verbose mode effects
  assert "[[ \"$stdout\" == *\"verbosity enabled\"* ]]" "Output should indicate that verbosity is enabled"
  assert "[[ \"$stdout\" == *\"loaded libraries: test_lib\"* ]]" "Output should list loaded libraries in verbose mode"
  
  # More direct test for verbose in MFLIBS_LOADED
  local found_verbose=0
  for item in "${MFLIBS_LOADED[@]}"; do
    if [[ "$item" == "verbose" ]]; then
      found_verbose=1
      break
    fi
  done
  assert_equals 1 $found_verbose "MFLIBS_LOADED should contain the 'verbose' value"
  
  # Clean up
  rm -rf "$test_dir"
  rm -f "/tmp/stdout_output"
  teardown
}
