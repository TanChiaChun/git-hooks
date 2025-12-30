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

@test "empty()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    run run_ci_project 'pytest'
    [ "$status" -eq 0 ]
    [[ "$output" == *'No tests were collected' ]]
}

@test "pass()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    mkdir 'src'
    cp "$BATS_TEST_DIRNAME/sample_python/pytest_pass.sample" \
        './src/test_sample.py'
    run run_ci_project 'pytest'
    [ "$status" -eq 0 ]
}

@test "fail()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    cp "$BATS_TEST_DIRNAME/sample_python/pytest_fail.sample" 'test_sample.py'
    run run_ci_project 'pytest'
    [ "$status" -ne 0 ]
}

@test "pass_coverage()" {
    cp "$BATS_TEST_DIRNAME/../.env" .
    mkdir 'src'
    cp "$BATS_TEST_DIRNAME/sample_python/pytest_pass.sample" \
        './src/test_sample.py'
    run run_ci_project 'pytest_coverage'
    local is_exist_index_html='false'
    if [[ -f './htmlcov/index.html' ]]; then
        is_exist_index_html='true'
    fi
    [ "$status" -eq 0 ]
    [ "$is_exist_index_html" == 'true' ]
}
