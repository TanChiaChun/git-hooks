setup() {
    load '../src/ci.sh'

    export py_test_file="${BATS_TEST_FILENAME%/*}/test.py"
}

teardown() {
    if [[ -f "$py_test_file" ]]; then
        rm "$py_test_file"
    fi
    if [[ -d "${BATS_TEST_FILENAME%/*}/__pycache__" ]]; then
        rm -r "${BATS_TEST_FILENAME%/*}/__pycache__"
    fi
}

@test "empty()" {
    cd "$BATS_TMPDIR"
    run run_ci_python_test
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == 'unittest tests directory not found' ]
}

@test "unittest_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_python/unittest_pass.sample" "$py_test_file"
    run run_ci_python_test 'unittest'
    [ "$status" -eq 0 ]
}

@test "unittest_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/unittest_fail.sample" "$py_test_file"
    run run_ci_python_test 'unittest'
    [ "$status" -ne 0 ]
}

@test "coverage_py_pass()" {
    if [[ -f './.coverage' ]]; then
        rm './.coverage'
    fi
    if [[ -d './htmlcov' ]]; then
        rm -r './htmlcov'
    fi

    cp "$BATS_TEST_DIRNAME/sample_python/unittest_pass.sample" "$py_test_file"
    run run_ci_python_test 'coverage_py'
    local is_exist_index_html='false'
    if [[ -f './htmlcov/index.html' ]]; then
        is_exist_index_html='true'
    fi
    rm './.coverage'
    rm -r './htmlcov'
    [ "$status" -eq 0 ]
    [ "$is_exist_index_html" == 'true' ]
}

@test "coverage_py_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/unittest_fail.sample" "$py_test_file"
    run run_ci_python_test 'coverage_py'
    rm './.coverage'
    [ "$status" -ne 0 ]
}

@test "invalid_choice()" {
    mapfile -t expected_output <<EOF
##################################################
Running invalid
##################################################
Invalid test choice
EOF
    run run_ci_python_test 'invalid'
    [ "$status" -eq 1 ]
    local OLD_IFS="$IFS"
    IFS=$'\n'
    [ "$output" == "${expected_output[*]}" ]
    IFS="$OLD_IFS"
}

@test "django_invalid_choice()" {
    run run_ci_python_test_django 'invalid'
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid django test choice' ]
}
