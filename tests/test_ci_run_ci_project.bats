setup() {
    load '../src/ci.sh'

    export tmp_dir="$BATS_TEST_DIRNAME/tmpdir"
    mkdir "$tmp_dir"
    cd "$tmp_dir" || exit 1
}

teardown() {
    cd "$OLDPWD" || exit 1
    rm -r "$tmp_dir"
}

@test "pytest_empty()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    run run_ci_project 'pytest'
    [ "$status" -eq 0 ]
    [[ "$output" == *'No tests were collected' ]]
}

@test "pytest_pass()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    cp "$BATS_TEST_DIRNAME/sample_python/pytest_pass.sample" 'test_sample.py'
    run run_ci_project 'pytest'
    [ "$status" -eq 0 ]
}

@test "pytest_fail()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    cp "$BATS_TEST_DIRNAME/sample_python/pytest_fail.sample" 'test_sample.py'
    run run_ci_project 'pytest'
    [ "$status" -ne 0 ]
}

@test "invalid_choice()" {
    mapfile -t expected_output <<EOF
##################################################
Running invalid
##################################################
Invalid CI choice
EOF
    run run_ci_project 'invalid'
    [ "$status" -eq 1 ]
    local OLD_IFS="$IFS"
    IFS=$'\n'
    [ "$output" == "${expected_output[*]}" ]
    IFS="$OLD_IFS"
}
