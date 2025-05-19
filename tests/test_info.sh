#!/usr/bin/env bash
# file: tests/test_info.sh

source "$(dirname "${BASH_SOURCE[0]}")/../src/libs/info.sh"

# Global variables for testing
TEST_IP_PATTERN="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

# Setup and teardown
setup() {
  # Create mock commands if needed
  :
}

teardown() {
  # Restore original commands if mocked
  :
}

# Tests for mflibs::info::ipv4::dig
test_info_ipv4_dig_basic() {
  # We mock the dig command to ensure predictable test results
  # Save the original function
  if declare -f dig >/dev/null 2>&1; then
    eval "original_dig() $(declare -f dig | tail -n +2)"
  fi
  
  # Mock the dig command
  dig() {
    echo "203.0.113.1"  # Using TEST-NET-3 address from reserved range
    return 0
  }
  
  # Run the test
  local ip=$(mflibs::info::ipv4::dig)
  local ret_code=$?
  
  # Restore original dig command
  if declare -f original_dig >/dev/null 2>&1; then
    eval "dig() $(declare -f original_dig | tail -n +2)"
    unset -f original_dig
  else
    unset -f dig
  fi
  
  # Test assertions
  assert_equals 0 $ret_code "Should return 0 on successful IP resolution"
  assert_matches "$TEST_IP_PATTERN" "$ip" "Should return a valid IPv4 address"
}

test_info_ipv4_dig_failure() {
  # Mock the dig command to simulate failure
  if declare -f dig >/dev/null 2>&1; then
    eval "original_dig() $(declare -f dig | tail -n +2)"
  fi
  
  # Mock the dig command to fail
  dig() {
    return 1
  }
  
  # Run the test
  mflibs::info::ipv4::dig >/dev/null 2>&1
  local ret_code=$?
  
  # Restore original dig command
  if declare -f original_dig >/dev/null 2>&1; then
    eval "dig() $(declare -f original_dig | tail -n +2)"
    unset -f original_dig
  else
    unset -f dig
  fi
  
  # Test assertions
  assert_equals 1 $ret_code "Should return 1 when dig fails"
}

# Tests for mflibs::info::ipv4::local
test_info_ipv4_local_basic() {
  # Mock the commands used for IP retrieval
  if declare -f ip >/dev/null 2>&1; then
    eval "original_ip() $(declare -f ip | tail -n +2)"
  fi
  
  # Mock the ip command
  ip() {
    echo "1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000"
    echo "    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00"
    echo "    inet 127.0.0.1/8 scope host lo"
    echo "    valid_lft forever preferred_lft forever"
    echo "2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000"
    echo "    link/ether 00:11:22:33:44:55 brd ff:ff:ff:ff:ff:ff"
    echo "    inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0"
    echo "    valid_lft forever preferred_lft forever"
  }
  
  # Run the test
  local ip=$(mflibs::info::ipv4::local)
  local ret_code=$?
  
  # Restore original ip command
  if declare -f original_ip >/dev/null 2>&1; then
    eval "ip() $(declare -f original_ip | tail -n +2)"
    unset -f original_ip
  else
    unset -f ip
  fi
  
  # Test assertions
  assert_equals 0 $ret_code "Should return 0 on successful IP resolution"
  assert_equals "192.168.1.100" "$ip" "Should extract the correct local IP address"
}

# Note: Testing the failure case for mflibs::info::ipv4::local is challenging in this test environment
# due to how bash handles pipelines and return codes. The function uses a pipeline with '&&' 
# that makes it difficult to properly mock the failure conditions within bash_unit.
# A real-world failure would occur if no non-loopback interface is available or if 'ip' command fails.

# The assert_matches function for regex pattern matching
# This is a helper function used in the tests
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
