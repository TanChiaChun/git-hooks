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

@test "pass" {
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint.config.sample" 'eslint.config.mts'
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint_pass.sample" 'main.ts'
    run run_ci_project 'eslint'
    [ "$status" -eq 0 ]
}

@test "fail" {
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint.config.sample" 'eslint.config.mts'
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint_fail.sample" 'main.ts'
    run run_ci_project 'eslint'
    [ "$status" -ne 0 ]
}
