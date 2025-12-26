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

@test "ts_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_ts_pass.sample" 'main.ts'
    run run_ci_project 'vue-tsc'
    [ "$status" -eq 0 ]
}

@test "ts_fail_assign()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_ts_fail_assign.sample" 'main.ts'
    run run_ci_project 'vue-tsc'
    [ "$status" -ne 0 ]
}

@test "ts_fail_parameter()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_ts_fail_parameter.sample" \
        'main.ts'
    run run_ci_project 'vue-tsc'
    [ "$status" -ne 0 ]
}

@test "ts_fail_wrong_return()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_ts_fail_wrong_return.sample" \
        'main.ts'
    run run_ci_project 'vue-tsc'
    [ "$status" -ne 0 ]
}

@test "vue_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_vue_pass.sample" 'App.vue'
    run run_ci_project 'vue-tsc'
    [ "$status" -eq 0 ]
}

@test "vue_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vue_tsc_vue_fail.sample" 'App.vue'
    run run_ci_project 'vue-tsc'
    [ "$status" -ne 0 ]
}
