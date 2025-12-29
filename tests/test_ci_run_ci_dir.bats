setup() {
    load '../src/ci.sh'

    cd "$BATS_TMPDIR" || exit 1
}

teardown() {
    cd "$OLDPWD" || exit 1
}

@test "bats_empty()" {
    mapfile -t expected_output <<EOF
##################################################
Running bats
##################################################
bats tests directory not found
EOF
    run run_ci_dir 'bats'
    [ "$status" -eq 0 ]
    local OLD_IFS="$IFS"
    IFS=$'\n'
    [ "$output" == "${expected_output[*]}" ]
    IFS="$OLD_IFS"
}

@test "bats_pass()" {
    mkdir 'tests'
    cp "$BATS_TEST_DIRNAME/sample_bash/test_pass.bats.sample" \
        './tests/test_ci.bats'
    run run_ci_dir 'bats'
    rm -r './tests'
    [ "$status" -eq 0 ]
}

@test "bats_fail()" {
    mkdir 'tests'
    cp "$BATS_TEST_DIRNAME/sample_bash/test_fail.bats.sample" \
        './tests/test_ci.bats'
    run run_ci_dir 'bats'
    rm -r './tests'
    [ "$status" -ne 0 ]
}

@test "markdown_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_markdown/markdown_pass.sample" 'test.md'
    run run_ci_dir 'markdown'
    rm './test.md'
    [ "$status" -eq 0 ]
}

@test "markdown_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_markdown/markdown_fail.sample" 'test.md'
    run run_ci_dir 'markdown'
    rm './test.md'
    [ "$status" -ne 0 ]
}

@test "invalid_choice()" {
    mapfile -t expected_output <<EOF
##################################################
Running invalid
##################################################
Invalid CI choice
EOF
    run run_ci_dir 'invalid'
    [ "$status" -eq 1 ]
    local OLD_IFS="$IFS"
    IFS=$'\n'
    [ "$output" == "${expected_output[*]}" ]
    IFS="$OLD_IFS"
}
