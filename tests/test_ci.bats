setup_file() {
    export sh_file="$BATS_TMPDIR/test.sh"
}

setup() {
    load ../src/ci.sh
}

@test "get_first_env_var()" {
    local env_file="$BATS_TMPDIR/.env"
    local env_name='PYTHONPATH'
    local env_line="$env_name=./src/"

    echo "$env_line" >"$env_file"

    run get_first_env_var "$env_file" "$env_name"
    rm "$env_file"
    [ "$status" -eq 0 ]
    [ "$output" == "$env_line" ]
}

@test "print_files()" {
    mapfile -t expected_output <<"EOF"
##################################################
Files to check:
src/ci.sh
src/pre-commit
##################################################
EOF

    run print_files 'src/ci.sh' 'src/pre-commit'
    [ "$status" -eq 0 ]

    local OLD_IFS="$IFS"
    IFS=$'\n'
    [ "$output" == "${expected_output[*]}" ]
    IFS="$OLD_IFS"
}

@test "run_ci_bats()" {
    local bats_success_file="$BATS_TEST_DIRNAME/test_success.bats.sample"
    local bats_fail_file="$BATS_TEST_DIRNAME/test_fail.bats.sample"

    cp "$bats_success_file" "$sh_file"

    run run_ci 'bats'
    [ "$status" -eq 0 ]

    cp "$bats_fail_file" "$sh_file"

    run run_ci 'bats'
    [ "$status" -ne 0 ]
}

@test "run_ci_shellcheck()" {
    cat <<"EOF" >"$sh_file"
#!/usr/bin/env bash

echo "Hello"
EOF

    run run_ci 'shellcheck'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$sh_file"
#!/usr/bin/env bash

echo "Hello\n"
EOF

    run run_ci 'shellcheck'
    [ "$status" -ne 0 ]
}

@test "run_ci_shfmt()" {
    cat <<"EOF" >"$sh_file"
#!/usr/bin/env bash

echo 'Hello'
EOF

    run run_ci 'shfmt'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$sh_file"
#!/usr/bin/env bash

 echo 'Hello'
EOF

    run run_ci 'shfmt'
    [ "$status" -ne 0 ]
}

teardown_file() {
    if [[ -e "$sh_file" ]]; then
        rm "$sh_file"
    fi
}
