setup() {
    load '../src/py.sh'
}

@test "get_venv_bin_path_posix()" {
    cd "$BATS_TMPDIR"
    mkdir -p 'venv/bin'
    run get_venv_bin_path '.'
    rm -r './venv'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == './venv/bin' ]
}

@test "get_venv_bin_path_windows()" {
    cd "$BATS_TMPDIR"
    mkdir -p 'venv/Scripts'
    run get_venv_bin_path '.'
    rm -r './venv'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == './venv/Scripts' ]
}

@test "get_venv_bin_path_custom_dir()" {
    mkdir "$BATS_TMPDIR/venv"
    mkdir "$BATS_TMPDIR/venv/bin"
    run get_venv_bin_path "$BATS_TMPDIR"
    rm -r "$BATS_TMPDIR/venv"
    [ "$status" -eq 0 ]
    [ "$output" == "$BATS_TMPDIR/venv/bin" ]
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

@test "project_venv()" {
    cd "$BATS_TMPDIR"
    create_project_venv
    activate_project_venv_bash

    local venv_bin_path
    venv_bin_path="$(get_venv_bin_path '.')"
    local python_path
    python_path="$(which python)"

    deactivate
    rm -r './venv'
    cd "$OLDPWD"

    local expected="${venv_bin_path:1}/python"
    [[ "$python_path" =~ .*"$expected" ]]
}
