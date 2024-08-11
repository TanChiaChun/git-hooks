setup() {
    load '../src/py.sh'

    export env_file='./.env'
    export py_dir='./mysite'
    export py_file="$py_dir/manage.py"
    cd "$BATS_TMPDIR" || exit 1
    mkdir "$py_dir"
}

teardown() {
    rm -r "$py_dir"
    rm "$env_file"
    cd "$OLDPWD" || exit 1
}

@test "output_check()" {
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    echo 'os.environ.setdefault("DJANGO_SETTINGS_MODULE", "mysite.settings")' \
        >"$py_file"
    run set_django_env_var
    [ "$status" -eq 0 ]
    [ "$output" == 'Set DJANGO_SETTINGS_MODULE to mysite.settings' ]
}

@test "export_check()" {
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    echo 'os.environ.setdefault("DJANGO_SETTINGS_MODULE", "mysite.settings")' \
        >"$py_file"
    set_django_env_var
    local export_p
    export_p="$(export -p | grep --max-count=1 'DJANGO_SETTINGS_MODULE')"
    [ "$export_p" == 'declare -x DJANGO_SETTINGS_MODULE="mysite.settings"' ]
}

@test "no_env_file()" {
    run set_django_env_var
    [ "$status" -eq 1 ]
    [[ "$output" == *'Django environment variables not set' ]]
}

@test "no_env_line()" {
    echo 'MAY_DJANGO_PROJECT=./mysite' >"$env_file"
    run set_django_env_var
    [ "$status" -eq 1 ]
    [ "$output" == 'Django environment variables not set' ]
}

@test "no_django_env_line()" {
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    echo 'os.environ.setdefault("DAJANGO_SETTINGS_MODULE", "mysite.settings")' \
        >"$py_file"
    run set_django_env_var
    [ "$status" -eq 1 ]
    [ "$output" == 'Django environment variables not set' ]
}

@test "regex_mismatch()" {
    echo 'MY_DJANGO_PROJECT=./mysite' >"$env_file"
    echo 'os.environ.setdefault("DJANGO", "SETTINGS", "mysite.settings")' \
        >"$py_file"
    run set_django_env_var
    [ "$status" -eq 1 ]
    [ "$output" == 'Django environment variables not set' ]
}
