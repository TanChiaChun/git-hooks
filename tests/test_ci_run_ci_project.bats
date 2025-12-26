setup() {
    load '../src/ci.sh'
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
