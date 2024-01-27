setup_file() {
    export test_file="$BATS_TMPDIR/test"
    export py_test_file="${BATS_TEST_FILENAME%/*}/test.py"
}

setup() {
    load '../src/ci.sh'
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

@test "get_parent_dir()" {
    run get_parent_dir '/path/bash.sh'
    [ "$status" -eq 0 ]
    [ "$output" == '/path' ]
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

    # Cannot test fail test case for now as filter_git_files.py has been set to
    # always output 1 file when run from Bats.
}

@test "prepend_venv_bin_to_path()" {
    local test_dir="$BATS_TMPDIR/venv"

    mkdir "$test_dir"
    cd "$test_dir"
    export GITHUB_ACTIONS='false'
    run prepend_venv_bin_to_path
    cd "$OLDPWD"
    rm -r "$test_dir"
    [ "$status" -eq 1 ]
    [ "$output" == 'Cannot find venv binary directory' ]

    export GITHUB_ACTIONS='true'
    run prepend_venv_bin_to_path
    export -n GITHUB_ACTIONS
    [ "$status" -eq 0 ]
    [ "$output" == \
        'Skip prepend venv bin to Path as running from GitHub Actions' ]
}

@test "run_ci_bats()" {
    local bats_success_file="$BATS_TEST_DIRNAME/test_success.bats.sample"
    local bats_fail_file="$BATS_TEST_DIRNAME/test_fail.bats.sample"

    cp "$bats_success_file" "$test_file"
    run run_ci 'bats'
    [ "$status" -eq 0 ]

    cp "$bats_fail_file" "$test_file"
    run run_ci 'bats'
    [ "$status" -ne 0 ]
}

@test "run_ci_black()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
pass
EOF
    run run_ci 'black'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
l = ["very", "very", "long", "long", "long", "list", "list", "list", "list", "list"]
EOF
    run run_ci 'black'
    [ "$status" -ne 0 ]
}

@test "run_ci_isort()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
import re
import string
EOF
    run run_ci 'isort'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
import string
import re
EOF
    run run_ci 'isort'
    [ "$status" -ne 0 ]
}

@test "run_ci_markdown()" {
    cat <<"EOF" >"$test_file"
# git-hooks
EOF
    run run_ci 'markdown'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
# git-hooks

EOF
    run run_ci 'markdown'
    [ "$status" -ne 0 ]
}

@test "run_ci_mypy()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
def main() -> None:
    """Main function."""
    pass


if __name__ == "__main__":
    main()
EOF
    run run_ci 'mypy'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
def main():
    """Main function."""
    pass


if __name__ == "__main__":
    main()
pass
EOF
    run run_ci 'mypy'
    [ "$status" -ne 0 ]
}

@test "run_ci_pylint()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
EOF
    run run_ci 'pylint'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
pass
EOF
    run run_ci 'pylint'
    [ "$status" -ne 0 ]
}

@test "run_ci_python_unittest()" {
    cd "$BATS_TMPDIR"
    run run_ci_python_unittest
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == 'unittest tests directory not found' ]

    prepend_venv_bin_to_path

    cat <<"EOF" >"$py_test_file"
import unittest


class TestModule(unittest.TestCase):
    def test_main(self) -> None:
        self.assertEqual(0, 0)


if __name__ == "__main__":
    unittest.main()
EOF
    run run_ci_python_unittest
    [ "$status" -eq 0 ]

    rm -r "${BATS_TEST_FILENAME%/*}/__pycache__"
    cat <<"EOF" >"$py_test_file"
import unittest


class TestModule(unittest.TestCase):
    def test_main(self) -> None:
        self.assertEqual(0, 1)


if __name__ == "__main__":
    unittest.main()
EOF
    run run_ci_python_unittest
    [ "$status" -ne 0 ]
}

@test "run_ci_shellcheck()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo "Hello"
EOF
    run run_ci 'shellcheck'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo "Hello\n"
EOF
    run run_ci 'shellcheck'
    [ "$status" -ne 0 ]
}

@test "run_ci_shfmt()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo 'Hello'
EOF
    run run_ci 'shfmt'
    [ "$status" -eq 0 ]

    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

 echo 'Hello'
EOF
    run run_ci 'shfmt'
    [ "$status" -ne 0 ]
}

@test "set_git_hooks_working_dir()" {
    declare -g git_hooks_working_dir # To clear shellcheck SC2154

    run set_git_hooks_working_dir
    [ "$status" -eq 0 ]
    [[ "$git_hooks_working_dir" == *'/git-hooks' ]]

    cd "$BATS_TMPDIR"
    mkdir "$BATS_TMPDIR/git-hooks"
    run set_git_hooks_working_dir
    rm -r './git-hooks'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]

    cd "$BATS_TMPDIR"
    run set_git_hooks_working_dir
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
    [ "$output" == 'Unsupported git-hooks working directory' ]
}

@test "update_path()" {
    run update_path 'path'
    [ "$status" -eq 0 ]
    [[ "$output" == *'/path' ]]

    run update_path './path'
    [ "$status" -eq 1 ]
    [ "$output" == 'Path should not start with . or /' ]

    run update_path '/path'
    [ "$status" -eq 1 ]
    [ "$output" == 'Path should not start with . or /' ]

    cd "$BATS_TMPDIR"
    echo '' >'./test.ini'
    run update_path 'test.ini'
    rm './test.ini'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == './test.ini' ]
}

teardown_file() {
    if [[ -f "$test_file" ]]; then
        rm "$test_file"
    fi
    if [[ -f "$py_test_file" ]]; then
        rm "$py_test_file"
    fi
}
