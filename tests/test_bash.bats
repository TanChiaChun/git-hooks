setup() {
    load ../src/bash.sh
}

@test "get_first_env_var()" {
    local env_file="$BATS_TMPDIR/.env"
    local env_name='PYTHONPATH'
    local env_line="$env_name=./src/"

    echo "$env_line" > "$env_file"

    run get_first_env_var "$env_file" "$env_name"
    [ "$status" -eq 0 ]
    [ "$output" == "$env_line" ]

    rm "$env_file"
}