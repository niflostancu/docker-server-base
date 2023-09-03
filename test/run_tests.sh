#!/bin/bash
# Base image tests

TESTS=(base services cmd create_user modify_user)

if [[ -n "$DUMMY_TESTS" ]]; then
    TESTS+=(dummy fail)
fi

# declare the image to be tested
BASE_IMAGE=${BASE_IMAGE:-niflostancu/server-base:latest}
TEST_IMAGE_BUILD=${TEST_IMAGE:-niflostancu/server-base-test:latest}
TEST_IMAGE=${BASE_IMAGE}

SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

function test_base_before() {
    DOCKER_ARGS+=(-e "PUID=1001" -e "PGID=1002")
}
function test_base() {
    # base image testing
    dtest_exec wait-for-boot
    dtest_goss "test_base.yaml"
}

function test_services_before() {
    (
        cd "$SDIR"
        pwd
        DTEST_BUILD_ARGS=(--pull=false  --load --build-arg "SERVER_BASE=$BASE_IMAGE" -t "$TEST_IMAGE_BUILD" .)
        _debug docker buildx  b "${DTEST_BUILD_ARGS[@]}"
        docker buildx --builder default b "${DTEST_BUILD_ARGS[@]}"
    )
    TEST_IMAGE=$TEST_IMAGE_BUILD
}
function test_services() {
    dtest_exec wait-for-boot
    dtest_goss "test_services.yaml"
}

# tests the docker one-time command running
function test_cmd_before() {
    DOCKER_CMD=(sleep 123)
    # add sample init script to the container (it needs to be readwrite, so copy
    # it to the tmp volume)
    dtest_copy init_cmd
    DOCKER_ARGS+=(-v "$TEST_TMP/init_cmd:/etc/cont-init.d/20-cmd")
}
function test_cmd() {
    dtest_exec wait-for-boot
    dtest_goss "test_cmd.yaml"
}

function test_create_user_before() {
    DOCKER_ARGS=(-e "CONT_USER=testuser" -e "CONT_UID=2023")
    TEST_IMAGE=$BASE_IMAGE
}
function test_create_user() {
    dtest_exec wait-for-boot
    dtest_goss "test_user.yaml"
}

function test_modify_user_before() {
    DOCKER_ARGS=(-e "CONT_USER=testuser" -e "CONT_UID=2023")
    TEST_IMAGE=$TEST_IMAGE_BUILD
}
function test_modify_user() {
    dtest_exec wait-for-boot
    dtest_goss "test_user.yaml"
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

