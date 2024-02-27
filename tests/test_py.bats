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
    cd "$BATS_TMPDIR"
    mkdir "$BATS_TMPDIR/venv"
    mkdir "$BATS_TMPDIR/venv/bin"
    run get_venv_bin_path "$BATS_TMPDIR"
    rm -r "$BATS_TMPDIR/venv"
    cd "$OLDPWD"
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

@test "set_django_env_var_output_check()" {
    local env_file='./.env'
    local py_dir='./mysite'
    local py_file="$py_dir/manage.py"

    cd "$BATS_TMPDIR"
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    mkdir "$py_dir"
    echo 'os.environ.setdefault("DJANGO_SETTINGS_MODULE", "mysite.settings")' \
        >"$py_file"
    run set_django_env_var
    rm -r "$py_dir"
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == 'Set DJANGO_SETTINGS_MODULE to mysite.settings' ]
}

@test "set_django_env_var_export_check()" {
    local env_file='./.env'
    local py_dir='./mysite'
    local py_file="$py_dir/manage.py"

    cd "$BATS_TMPDIR"
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    mkdir "$py_dir"
    echo 'os.environ.setdefault("DJANGO_SETTINGS_MODULE", "mysite.settings")' \
        >"$py_file"
    set_django_env_var
    local export_p
    export_p="$(export -p | grep --max-count=1 'DJANGO_SETTINGS_MODULE')"
    rm -r "$py_dir"
    rm "$env_file"
    cd "$OLDPWD"
    [ "$export_p" == 'declare -x DJANGO_SETTINGS_MODULE="mysite.settings"' ]
}

@test "set_django_env_var_no_env_file()" {
    cd "$BATS_TMPDIR"
    run set_django_env_var
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
}

@test "set_django_env_var_no_env_line()" {
    local env_file='./.env'

    cd "$BATS_TMPDIR"
    echo 'MAY_DJANGO_PROJECT=./mysite' >"$env_file"
    run set_django_env_var
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
}

@test "set_django_env_var_no_django_env_line()" {
    local env_file='./.env'
    local py_dir='./mysite'
    local py_file="$py_dir/manage.py"

    cd "$BATS_TMPDIR"
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    mkdir "$py_dir"
    echo 'os.environ.setdefault("DAJANGO_SETTINGS_MODULE", "mysite.settings")' \
        >"$py_file"
    run set_django_env_var
    rm -r "$py_dir"
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
}

@test "set_django_env_var_regex_mismatch()" {
    local env_file='./.env'
    local py_dir='./mysite'
    local py_file="$py_dir/manage.py"

    cd "$BATS_TMPDIR"
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    mkdir "$py_dir"
    echo 'os.environ.setdefault("DJANGO", "SETTINGS", "mysite.settings")' \
        >"$py_file"
    run set_django_env_var
    rm -r "$py_dir"
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
}
