#!/bin/bash
# Base image tests

TESTS=(base)

if [[ -n "$DUMMY_TESTS" ]]; then
    TESTS=(base dummy fail)
fi

# declare the image to be tested
TEST_IMAGE=${TEST_IMAGE:-nicloud/server-base}

function test_base_before() {
    DOCKER_ARGS+=(-e "PUID=1001" -e "PGID=1002")
}
function test_base() {
    # base image testing
    dtest_exec wait-for-services
    dtest_goss "test_base.yaml"
}

function test_dummy() {
    dtest_exec true
}

# A test that fails; used to test the testing framework ;)
function test_fail() {
    dtest_exec false
}

# Source the testing framework
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
. "$SDIR/_dtest.sh"

# run the tests!
run_tests

