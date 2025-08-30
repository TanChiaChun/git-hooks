setup() {
    load '../src/ci.sh'
}

@test "handle_ci_fail()" {
    mapfile -t expected_output <<EOF
$(echo_red_text '##################################################')
$(echo_red_text 'unittest fail')
$(echo_red_text '##################################################')
EOF
    run handle_ci_fail 'unittest'
    [ "$status" -eq 1 ]
    local OLD_IFS="$IFS"
    IFS=$'\n'
    [ "$output" == "${expected_output[*]}" ]
    IFS="$OLD_IFS"
}

@test "has_python_files()" {
    run has_python_files
    [ "$status" -eq 0 ]

    # Cannot test fail test case for now as git_files_filter.py has been set to
    # always output 1 file when run from Bats.
}

@test "set_git_hooks_working_dir_current_repo()" {
    declare -g git_hooks_working_dir # To clear shellcheck SC2154

    run set_git_hooks_working_dir
    [ "$status" -eq 0 ]
    [[ "$output" == "Set git-hooks working directory to '"*"/git-hooks'" ]]
    [[ "$git_hooks_working_dir" == *'/git-hooks' ]]
}

@test "set_git_hooks_working_dir_submodule_repo()" {
    cd "$BATS_TMPDIR"
    mkdir "$BATS_TMPDIR/git-hooks"
    run set_git_hooks_working_dir
    rm -r './git-hooks'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [[ "$output" == "Set git-hooks working directory to '"*"/git-hooks'" ]]
    [[ "$git_hooks_working_dir" == *'/git-hooks' ]]
}

@test "set_git_hooks_working_dir_fail()" {
    cd "$BATS_TMPDIR"
    run set_git_hooks_working_dir
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
    [ "$output" == 'Unsupported git-hooks working directory' ]
}

@test "source_sh_script_dir()" {
    run source_sh_script_dir 'helper.sh'
    [ "$status" -eq 0 ]
}

@test "source_sh_script_dir_not_found()" {
    run source_sh_script_dir 'invalid.sh'
    [ "$status" -eq 1 ]
    [[ "$output" == *" not found" ]]
}

@test "update_path()" {
    run update_path 'path'
    [ "$status" -eq 0 ]
    [[ "$output" == *'/path' ]]
}

@test "update_path2()" {
    cd "$BATS_TMPDIR"
    echo '' >'./test.ini'
    run update_path 'test.ini'
    rm './test.ini'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == './test.ini' ]
}

@test "update_path_fail_dot()" {
    run update_path './path'
    [ "$status" -eq 1 ]
    [ "$output" == 'Path should not start with . or /' ]
}

@test "update_path_fail_slash()" {
    run update_path '/path'
    [ "$status" -eq 1 ]
    [ "$output" == 'Path should not start with . or /' ]
}
