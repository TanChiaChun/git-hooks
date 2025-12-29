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

@test "lint_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_python/ruff_lint_pass.sample" 'test.py'
    run run_ci_project 'ruff_lint'
    [ "$status" -eq 0 ]
}

@test "lint_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/ruff_lint_fail.sample" 'test.py'
    run run_ci_project 'ruff_lint'
    [ "$status" -ne 0 ]
}
