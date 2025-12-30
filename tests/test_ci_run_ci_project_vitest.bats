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

@test "ts_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vitest_ts_test_pass.sample" 'main.test.ts'
    run run_ci_project 'vitest'
    [ "$status" -eq 0 ]
}

@test "ts_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vitest_ts_test_fail.sample" 'main.test.ts'
    run run_ci_project 'vitest'
    [ "$status" -ne 0 ]
}

@test "vue_pass()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vite.config.sample" 'vite.config.ts'
    cp "$BATS_TEST_DIRNAME/sample_vue/vitest_vue.sample" 'CounterItem.vue'
    mkdir '__test__'
    cp "$BATS_TEST_DIRNAME/sample_vue/vitest_vue_test_pass.sample" \
        './__test__/CounterItem.test.ts'
    run run_ci_project 'vitest'
    [ "$status" -eq 0 ]
}

@test "vue_fail()" {
    cp "$BATS_TEST_DIRNAME/sample_vue/vite.config.sample" 'vite.config.ts'
    cp "$BATS_TEST_DIRNAME/sample_vue/vitest_vue.sample" 'CounterItem.vue'
    mkdir '__test__'
    cp "$BATS_TEST_DIRNAME/sample_vue/vitest_vue_test_fail.sample" \
        './__test__/CounterItem.test.ts'
    run run_ci_project 'vitest'
    [ "$status" -ne 0 ]
}
