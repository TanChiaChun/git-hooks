setup() {
    load '../src/ci.sh'

    export tmp_dir="$BATS_TEST_DIRNAME/tmpdir"
    mkdir "$tmp_dir"
    cp "$BATS_TEST_DIRNAME/sample_vue/tsconfig.json" "$tmp_dir"
    cd "$tmp_dir" || exit 1
}

teardown() {
    cd "$OLDPWD" || exit 1
    rm -r "$tmp_dir"
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
