setup() {
    load '../src/ci.sh'

    export env_file="./.env"
    cd "$BATS_TMPDIR" || exit 1
}

teardown() {
    if [[ -f "$env_file" ]]; then
        rm "$env_file"
    fi
    cd "$OLDPWD" || exit 1
}

@test "pass()" {
    local env_value='./src/'

    echo "PYTHONPATH=$env_value" >"$env_file"
    run get_pythonpath_value
    [ "$status" -eq 0 ]
    [ "$output" == "$env_value" ]
}

@test "fail_invalid_env()" {
    echo '' >"$env_file"
    run get_pythonpath_value
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid env line' ]
}

@test "fail_multi_unix()" {
    echo 'PYTHONPATH=./src/:./dir' >"$env_file"
    run get_pythonpath_value
    [ "$status" -eq 1 ]
    [ "$output" == 'Multiple PYTHONPATH directories not supported for isort' ]
}

@test "fail_multi_windows()" {
    echo 'PYTHONPATH=./src/;./dir' >"$env_file"
    run get_pythonpath_value
    [ "$status" -eq 1 ]
    [ "$output" == 'Multiple PYTHONPATH directories not supported for isort' ]
}
