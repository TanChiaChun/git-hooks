setup() {
    load '../src/ci.sh'

    export tmp_dir="$BATS_TEST_DIRNAME/tmpdir"
    mkdir "$tmp_dir"
    mkdir "$tmp_dir/src"
    cd "$tmp_dir" || exit 1
}

teardown() {
    cd "$OLDPWD" || exit 1
    rm -r "$tmp_dir"
}

@test "ts_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_ts_pass.sample" './src/main.ts'
    run run_ci_project 'prettier'
    [ "$status" -eq 0 ]
}

@test "ts_fail_single_quote()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_ts_fail_single_quote.sample" \
        './src/main.ts'
    run run_ci_project 'prettier'
    [ "$status" -ne 0 ]
}

@test "ts_fail_tab_width()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_ts_fail_tab_width.sample" \
        './src/main.ts'
    run run_ci_project 'prettier'
    [ "$status" -ne 0 ]
}

@test "vue_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_vue_pass.sample" './src/App.vue'
    run run_ci_project 'prettier'
    [ "$status" -eq 0 ]
}

@test "vue_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_vue_fail.sample" './src/App.vue'
    run run_ci_project 'prettier'
    [ "$status" -ne 0 ]
}
