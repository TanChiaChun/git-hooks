setup() {
    load '../src/ci.sh'

    export test_file="$BATS_TMPDIR/test"
}

teardown() {
    if [[ -f "$test_file" ]]; then
        rm "$test_file"
    fi
}

@test "shfmt_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_bash/shfmt_pass.sample" "$test_file"
    run run_ci_files 'shfmt'
    [ "$status" -eq 0 ]
}

@test "shfmt_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_bash/shfmt_fail.sample" "$test_file"
    run run_ci_files 'shfmt'
    [ "$status" -ne 0 ]
}

@test "shellcheck_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_bash/shellcheck_pass.sample" "$test_file"
    run run_ci_files 'shellcheck'
    [ "$status" -eq 0 ]
}

@test "shellcheck_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_bash/shellcheck_fail.sample" "$test_file"
    run run_ci_files 'shellcheck'
    [ "$status" -ne 0 ]
}

@test "bats_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_bash/test_pass.bats.sample" "$test_file"
    run run_ci_files 'bats'
    [ "$status" -eq 0 ]
}

@test "bats_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_bash/test_fail.bats.sample" "$test_file"
    run run_ci_files 'bats'
    [ "$status" -ne 0 ]
}

@test "black_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_python/black_pass.sample" "$test_file"
    run run_ci_files 'black'
    [ "$status" -eq 0 ]
}

@test "black_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/black_fail.sample" "$test_file"
    run run_ci_files 'black'
    [ "$status" -ne 0 ]
}

@test "pylint_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_python/pylint_pass.sample" "$test_file"
    run run_ci_files 'pylint'
    [ "$status" -eq 0 ]
}

@test "pylint_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/pylint_fail.sample" "$test_file"
    run run_ci_files 'pylint'
    [ "$status" -ne 0 ]
}

@test "mypy_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_python/mypy_pass.sample" "$test_file"
    run run_ci_files 'mypy'
    [ "$status" -eq 0 ]
}

@test "mypy_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/mypy_fail.sample" "$test_file"
    run run_ci_files 'mypy'
    [ "$status" -ne 0 ]
}

@test "isort_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_python/isort_pass.sample" "$test_file"
    run run_ci_files 'isort'
    [ "$status" -eq 0 ]
}

@test "isort_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_python/isort_fail.sample" "$test_file"
    run run_ci_files 'isort'
    [ "$status" -ne 0 ]
}

@test "markdown_pass()" {
    cd "$BATS_TMPDIR" || exit 1
    cp "$BATS_TEST_DIRNAME/sample_markdown/markdown_pass.sample" 'test.md'
    run run_ci_files 'markdown'
    cd "$OLDPWD" || exit 1
    [ "$status" -eq 0 ]
}

@test "markdown_fail()" {
    cd "$BATS_TMPDIR" || exit 1
    cp "$BATS_TEST_DIRNAME/sample_markdown/markdown_fail.sample" 'test.md'
    run run_ci_files 'markdown'
    cd "$OLDPWD" || exit 1
    [ "$status" -ne 0 ]
}

@test "invalid_choice()" {
    run run_ci_files 'invalid'
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid CI choice' ]
}
