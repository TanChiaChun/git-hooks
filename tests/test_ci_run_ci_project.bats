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

@test "eslint_pass" {
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint.config.sample" 'eslint.config.mts'
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint_pass.sample" 'main.ts'
    run run_ci_project 'eslint'
    [ "$status" -eq 0 ]
}

@test "eslint_fail" {
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint.config.sample" 'eslint.config.mts'
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint_fail.sample" 'main.ts'
    run run_ci_project 'eslint'
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
