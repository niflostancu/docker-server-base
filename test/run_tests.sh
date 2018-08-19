#!/bin/bash
# Base image tests

TESTS=(base services)

if [[ -n "$DUMMY_TESTS" ]]; then
    TESTS=(base services dummy fail)
fi

# declare the image to be tested
TEST_IMAGE=${TEST_IMAGE:-nicloud/server-base}

SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

function test_base_before() {
    DOCKER_ARGS+=(-e "PUID=1001" -e "PGID=1002")
}
function test_base() {
    # base image testing
    dtest_exec wait-for-services
    dtest_goss "test_base.yaml"
}

function test_services_before() {
    # add a sample services as readonly volumes
    DOCKER_ARGS+=(-v "$SDIR/service-sampled:/etc/services.d/sampled:ro")
    DOCKER_ARGS+=(-v "$SDIR/service-down:/etc/services.d/downd:ro")
    DOCKER_ARGS+=(-e "S6_READ_ONLY_ROOT=1")
}
function test_services() {
    dtest_exec wait-for-services
    dtest_goss "test_services.yaml"
}

function test_dummy() {
    dtest_exec true
}

# A test that fails; used to test the testing framework ;)
function test_fail() {
    dtest_exec false
}

# Source the testing framework
. "$SDIR/_dtest.sh"

# run the tests!
run_tests

