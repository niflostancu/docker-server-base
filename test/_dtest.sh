#!/bin/bash
# Goss-based Docker image testing library, inspired by dgoss (but enhanced).
# Version 0.1

# All begins with the `run_tests` function: it takes the global $TESTS
# array (which contains the name of the test functions to run), setting up the
# environment and running each test.

# Variables

# The tests (function names) to run
((${#TESTS[@]})) || TESTS=()

# Goss binary path or download URL (empty - autodetect, use URL as last resort)
GOSS_PATH=${GOSS_PATH:-}
GOSS_URL=https://github.com/aelsabbahy/goss/releases/download/v0.3.6/goss-linux-amd64
GOSS_CACHE=/tmp/goss.cached

# Colors
NO_COLOR="\033[0m"
COLOR_info="\033[0;36m"
COLOR_success="\033[0;32m"
COLOR_error="\033[0;31m"

GOSS_OPTS=(--color --format documentation)

[[ ! -z "$DEBUG" ]] && DEBUG="echo "

_SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

# Testing primitives

# Prints colorful messages
function _ecolor() {
    local c="COLOR_$1"
    shift
    echo -e "${!c}$*${NO_COLOR}" >&2
}
function _debug() {
    if [[ "$DEBUG" -gt "0" ]]; then
        echo -e "> $*" >&2
    fi
}

# Returns the stack trace (used in case of test errors)
_STACKTRACE=
function save_stacktrace() {
    local i
    local stack_size=${#FUNCNAME[@]}
    _STACKTRACE=""
    # start with 1 to skip the get_stack function
    for (( i=1; i<$stack_size; i++ )); do
        local func="${FUNCNAME[$i]}"
        [ x$func = x ] && func=MAIN
        local linen="${BASH_LINENO[$(( i - 1 ))]}"
        local src="${BASH_SOURCE[$i]}"
        [ x"$src" = x ] && src=non_file_source
        _STACKTRACE+=$'\n'"   "$func"() in "$src":"$linen
    done
}

# Note: the following functions run inside the internal test subshell! 

# Downloads / copies goss to the docker volume
function dtest_copy_goss() {
    local goss_src="$GOSS_PATH"
    local which_goss=$(which goss 2>/dev/null)
    if [[ -z "$goss_src" ]] && [[ -x "$which_goss" ]]; then
        goss_src="$which_goss"
    elif [[ "$GOSS_URL" ]]; then
        goss_src="$GOSS_URL"
    fi
    if [[ "$goss_src" == "http"* ]]; then
        # check if already cached
        if [[ ! -f "$GOSS_CACHE" ]]; then
            _debug "downloading goss..."
            curl -L -o "$GOSS_CACHE" "$goss_src"
        fi
        goss_src="$GOSS_CACHE"
    fi

    if [[ ! -f "$goss_src" ]]; then
        error "FATAL: Unable to find / download goss!"
        echo "Please install it manually or set the correct URL to fetch it." >&2
        exit 1
    fi
    _debug "found goss in: $goss_src" >&2
    cp -f "$goss_src" "$TEST_TMP/goss"
}

# Starts the container; called by `init_test`
function _start_container() {
    # start the container with TEST_TMP as test volume
    _debug "docker run -d -v "$TEST_TMP:/test" "${DOCKER_ARGS[@]}" \
        "$TEST_IMAGE" "${DOCKER_CMD[@]}""
    CONTAINER_ID=$(docker run -d -v "$TEST_TMP:/test" "${DOCKER_ARGS[@]}" \
        "$TEST_IMAGE" "${DOCKER_CMD[@]}")
    _debug "container: $CONTAINER_ID"
}

# Execs a custom command within the container
function dtest_exec() {
    echo "\$" "$@" >&2
    docker exec "$CONTAINER_ID" "$@"
}

# Copies "$1" (relative to the source dir) to the test volume
function dtest_copy() {
    local ARGS=()
    for arg in "$@"; do
        # if it is an argument or absolute path, don't prepend source dir
        case "$arg" in
            [-/]*) arg="$arg" ;;
            *    ) arg="$_SDIR/$arg" ;;
        esac
        ARGS+=("$arg")
    done
    cp -f "${ARGS[@]}" "$TEST_TMP/"
}

function dtest_goss() {
    dtest_copy "$1"
    dtest_exec "/test/goss" --gossfile "/test/$1" validate "${GOSS_OPTS}"
}

function _indent() {
    sed 's/^/  /'
}

# Test cleanup function (internal test context).
function cleanup_test() {
    touch "$TEST_TMP/.notempty" || true
    ( shopt -s dotglob; [[ -n "$TEST_TMP" ]] && rm -rf "$TEST_TMP/"* ) || true
    if [[ -n "$CONTAINER_ID" ]]; then
        _debug "deleting container $CONTAINER_ID ..."
        docker rm -vf "$CONTAINER_ID" &> /dev/null || true
    fi
    CONTAINER_ID=
}

# Prints a friendly message with the test error
function report_test_error() {
    _ecolor error "\n$TEST_NAME: failed with code $ret!"
    echo -e "${ERR_COLOR}Stack trace:${NO_COLOR}$_STACKTRACE" >&2
    exit $ret
}

function global_cleanup() {
    [[ -n "$TEST_TMP" ]] && rm -rf "$TEST_TMP" || true
}

function run_tests() {
    # Initialize the temp dir
    if [[ -z "$TEST_TMP" ]]; then
        TEST_TMP=$(mktemp -d /tmp/dgoss.XXXXXXXXXX)
    fi
    chmod 777 "$TEST_TMP"
    trap global_cleanup EXIT

    for test in "${TESTS[@]}"; do
        # run each test in a separate subshell
        (
            TEST_NAME="test_$test"
            CONTAINER_ID=

            set -eE
            _ecolor info
            _ecolor info "Running $TEST_NAME..."
            trap 'ret=$?; save_stacktrace; report_test_error' ERR
            trap 'cleanup_test' EXIT

            _debug "temp dir: $TEST_TMP"
            dtest_copy_goss
            [[ "$(type -t "${TEST_NAME}_before")" == "function" ]] && \
                "${TEST_NAME}_before" || true

            _start_container

            "$TEST_NAME" | _indent
            TEST_EXIT_CODE=${PIPESTATUS[0]}
            _debug "test exited $TEST_EXIT_CODE"
            if [[ "$TEST_EXIT_CODE" -ne 0 ]]; then
                exit 1
            fi

            _ecolor success
            _ecolor success "$TEST_NAME passed!"

        )
        if [[ "$?" -ne 0 ]]; then
            echo >&2
            exit 1
        fi
    done
    _ecolor success "All tests passed!"
}

