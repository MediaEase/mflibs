#!/usr/bin/env bash
# file: tests/test_array.sh

source "$(dirname "${BASH_SOURCE[0]}")/../src/libs/array.sh"

# Test for mflibs::array::contains when the element is present
test_array_contains_with_element_present() {
  declare -a array=("chocolate" "berries" "truffle")
  mflibs::array::contains "berries" "${array[@]}"
  assert_equals 0 $? "Element 'berries' should be found in the array"
}

# Test for mflibs::array::contains when the element is absent
test_array_contains_with_element_absent() {
  declare -a array=("chocolate" "berries" "truffle")
  mflibs::array::contains "apple" "${array[@]}"
  assert_equals 1 $? "Element 'apple' should not be found in the array"
}

# Test for mflibs::array::contains when arguments are missing
test_array_contains_missing_arguments() {
  mflibs::array::contains
  assert_equals 2 $? "Function should return 2 when arguments are missing"
}

# Test for mflibs::array::is_empty with an empty array
test_array_is_empty_with_empty_array() {
  declare -a empty_array=()
  mflibs::array::is_empty "${empty_array[@]}"
  assert_equals 0 $? "Empty array should be detected as empty"
}

# Test for mflibs::array::is_empty with a non-empty array
test_array_is_empty_with_non_empty_array() {
  declare -a non_empty_array=("element")
  mflibs::array::is_empty "${non_empty_array[@]}"
  assert_equals 2 $? "Non-empty array should not be considered empty"
}

# Test for mflibs::array::glue with multiple elements
test_array_glue_with_elements() {
  declare -a array=("chocolate" "berries" "truffle")
  result=$(mflibs::array::glue "," "${array[@]}")
  assert_equals "chocolate,berries,truffle" "$result" "Elements should be joined with a comma"
}

# Test for mflibs::array::glue with missing arguments
test_array_glue_missing_arguments() {
  mflibs::array::glue
  assert_equals 2 $? "Function should return 2 when arguments are missing"
}

# Test for mflibs::array::merge with two arrays
test_array_merge() {
  declare -a array1=("chocolate" "berries")
  declare -a array2=("apple" "banana")
  
  readarray -t result <<< $(mflibs::array::merge "array1[@]" "array2[@]")
  
  assert_equals 4 "${#result[@]}" "Merged array should contain 4 elements"
  assert_equals "chocolate" "${result[0]}" "First element should be 'chocolate'"
  assert_equals "berries" "${result[1]}" "Second element should be 'berries'"
  assert_equals "apple" "${result[2]}" "Third element should be 'apple'"
  assert_equals "banana" "${result[3]}" "Fourth element should be 'banana'"
}

# Test for mflibs::array::merge with missing arguments
test_array_merge_missing_arguments() {
  mflibs::array::merge
  assert_equals 2 $? "Function should return 2 when arguments are missing"
}

# Test for mflibs::array::glue with an empty array
test_array_glue_with_empty_array() {
  declare -a empty_array=()
  result=$(mflibs::array::glue "," "${empty_array[@]}")
  assert_equals "" "$result" "An empty array should produce an empty string"
}

# Test for mflibs::array::glue with different delimiters
test_array_glue_with_different_delimiters() {
  declare -a array=("chocolate" "berries" "truffle")
  
  # Test with hyphen delimiter
  result=$(mflibs::array::glue "-" "${array[@]}")
  assert_equals "chocolate-berries-truffle" "$result" "Elements should be joined with a hyphen"
  
  # Test with space delimiter
  result=$(mflibs::array::glue " " "${array[@]}")
  assert_equals "chocolate berries truffle" "$result" "Elements should be joined with a space"
  
  # Test with no delimiter
  result=$(mflibs::array::glue "" "${array[@]}")
  assert_equals "chocolateberriestruffle" "$result" "Elements should be joined with no delimiter"
}

# Test for mflibs::array::glue with a single element
test_array_glue_with_single_element() {
  declare -a array=("chocolate")
  result=$(mflibs::array::glue "," "${array[@]}")
  assert_equals "chocolate" "$result" "Single element should not include delimiter"
}
