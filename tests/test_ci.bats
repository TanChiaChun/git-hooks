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

@test "run_ci_shellcheck()" {
    local sh_file="$BATS_TMPDIR/test.sh"

    cat <<"EOF" >"$sh_file"
#!/usr/bin/env bash

echo "Hello\n"
EOF

    run run_ci 'shellcheck'
    rm "$sh_file"
    [ "$status" -ne 0 ]
}

@test "run_ci_shfmt()" {
    local sh_file="$BATS_TMPDIR/test.sh"

    cat <<"EOF" >"$sh_file"
#!/usr/bin/env bash

 echo 'Hello'
EOF

    run run_ci 'shfmt'
    rm "$sh_file"
    [ "$status" -ne 0 ]
}
