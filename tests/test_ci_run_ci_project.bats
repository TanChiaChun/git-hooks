setup() {
    load '../src/ci.sh'

    export tmp_dir="$BATS_TEST_DIRNAME/tmpdir"
    mkdir "$tmp_dir"
    cp "$BATS_TEST_DIRNAME/sample_vue/tsconfig.sample" "$tmp_dir/tsconfig.json"
    cd "$tmp_dir" || exit 1
}

teardown() {
    cd "$OLDPWD" || exit 1
    rm -r "$tmp_dir"
}

@test "eslint_pass" {
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint.config.sample" 'eslint.config.mjs'
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint_pass.sample" 'main.js'
    run run_ci_project 'eslint'
    [ "$status" -eq 0 ]
}

@test "eslint_fail" {
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint.config.sample" 'eslint.config.mjs'
    cp "$BATS_TEST_DIRNAME/sample_vue/eslint_fail.sample" 'main.js'
    run run_ci_project 'eslint'
    [ "$status" -ne 0 ]
}

@test "prettier_ts_pass" {
    mkdir 'src'
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_ts_pass.sample" './src/main.ts'
    run run_ci_project 'prettier'
    [ "$status" -eq 0 ]
}

@test "prettier_ts_fail" {
    mkdir 'src'
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_ts_fail.sample" './src/main.ts'
    run run_ci_project 'prettier'
    [ "$status" -ne 0 ]
}

@test "prettier_vue_pass" {
    mkdir 'src'
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_vue_pass.sample" './src/App.vue'
    run run_ci_project 'prettier'
    [ "$status" -eq 0 ]
}

@test "prettier_vue_fail" {
    mkdir 'src'
    cp "$BATS_TEST_DIRNAME/sample_vue/prettier_vue_fail.sample" './src/App.vue'
    run run_ci_project 'prettier'
    [ "$status" -ne 0 ]
}

@test "vue-tsc_ts_pass" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_ts_pass.sample" 'main.ts'
    run run_ci_project 'vue-tsc'
    [ "$status" -eq 0 ]
}

@test "vue-tsc_ts_fail" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_ts_fail.sample" 'main.ts'
    run run_ci_project 'vue-tsc'
    [ "$status" -ne 0 ]
}

@test "vue-tsc_vue_pass" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_vue_pass.sample" 'App.vue'
    run run_ci_project 'vue-tsc'
    [ "$status" -eq 0 ]
}

@test "vue-tsc_vue_fail" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_vue_fail.sample" 'App.vue'
    run run_ci_project 'vue-tsc'
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
