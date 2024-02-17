setup() {
    load '../src/helper.sh'
}

@test "get_env_value()" {
    run get_env_value 'PYTHONPATH=./src/'
    [ "$status" -eq 0 ]
    [ "$output" == './src/' ]
}

@test "get_env_value_no_equal()" {
    run get_env_value 'PYTHONPATH./src/'
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid env line' ]
}

@test "get_env_value_no_key()" {
    run get_env_value '=./src/'
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid env line' ]
}

@test "get_env_value_no_value()" {
    run get_env_value 'PYTHONPATH='
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid env line' ]
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
