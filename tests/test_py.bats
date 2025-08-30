setup() {
    load '../src/py.sh'
}

@test "is_django_project_false()" {
    run is_django_project
    [ "$status" -eq 1 ]
}

@test "is_django_project_true()" {
    local env_file="./.env"

    cd "$BATS_TMPDIR"
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    run is_django_project
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
}
