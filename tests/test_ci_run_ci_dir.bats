setup() {
    load '../src/ci.sh'

    cd "$BATS_TMPDIR" || exit 1
}

teardown() {
    cd "$OLDPWD" || exit 1
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
