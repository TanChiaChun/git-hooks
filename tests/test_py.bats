setup() {
    load '../src/py.sh'
}

@test "get_venv_bin_path_custom_dir()" {
    mkdir "$BATS_TMPDIR/.venv"
    mkdir "$BATS_TMPDIR/.venv/bin"
    run get_venv_bin_path "$BATS_TMPDIR"
    rm -r "$BATS_TMPDIR/.venv"
    [ "$status" -eq 0 ]
    [ "$output" == "$BATS_TMPDIR/.venv/bin" ]
}

@test "get_venv_bin_path_posix()" {
    cd "$BATS_TMPDIR"
    mkdir -p '.venv/bin'
    run get_venv_bin_path '.'
    rm -r './.venv'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == './.venv/bin' ]
}

@test "get_venv_bin_path_windows()" {
    cd "$BATS_TMPDIR"
    mkdir -p '.venv/Scripts'
    run get_venv_bin_path '.'
    rm -r './.venv'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == './.venv/Scripts' ]
}
