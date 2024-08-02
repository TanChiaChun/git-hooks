setup_file() {
    export test_file="$BATS_TMPDIR/test"
    export py_test_file="${BATS_TEST_FILENAME%/*}/test.py"
}

setup() {
    load '../src/ci.sh'
}

@test "get_pythonpath_value()" {
    local env_file="./.env"
    local env_value='./src/'

    local env_line="PYTHONPATH=$env_value"
    cd "$BATS_TMPDIR"
    echo "$env_line" >"$env_file"
    run get_pythonpath_value
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == "$env_value" ]
}

@test "get_pythonpath_value_fail_invalid_env()" {
    local env_file="./.env"

    cd "$BATS_TMPDIR"
    echo '' >"$env_file"
    run get_pythonpath_value
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid env line' ]
}

@test "get_pythonpath_value_fail_multi_unix()" {
    local env_file="./.env"
    local env_value='./src/'

    local env_line="PYTHONPATH=$env_value:./dir"
    cd "$BATS_TMPDIR"
    echo "$env_line" >"$env_file"
    run get_pythonpath_value
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
    [ "$output" == 'Multiple PYTHONPATH directories not supported for isort' ]
}

@test "get_pythonpath_value_fail_multi_windows()" {
    local env_file="./.env"
    local env_value='./src/'

    local env_line="PYTHONPATH=$env_value;./dir"
    cd "$BATS_TMPDIR"
    echo "$env_line" >"$env_file"
    run get_pythonpath_value
    rm "$env_file"
    cd "$OLDPWD"
    [ "$status" -eq 1 ]
    [ "$output" == 'Multiple PYTHONPATH directories not supported for isort' ]
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

@test "prepend_venv_bin_to_path_not_found()" {
    local test_dir="$BATS_TMPDIR/venv"

    mkdir "$test_dir"
    cd "$test_dir"
    # shellcheck disable=SC2030
    export GITHUB_ACTIONS='false'
    run prepend_venv_bin_to_path
    export -n GITHUB_ACTIONS
    cd "$OLDPWD"
    rm -r "$test_dir"
    [ "$status" -eq 1 ]
    [ "$output" == 'Cannot find venv binary directory' ]
}

@test "prepend_venv_bin_to_path_github_actions()" {
    # shellcheck disable=SC2031
    export GITHUB_ACTIONS='true'
    run prepend_venv_bin_to_path
    export -n GITHUB_ACTIONS
    [ "$status" -eq 0 ]
    [ "$output" == \
        'Skip prepend venv bin to Path as running from GitHub Actions' ]
}

@test "run_ci_bats_pass()" {
    local bats_pass_file="$BATS_TEST_DIRNAME/test_pass.bats.sample"

    cp "$bats_pass_file" "$test_file"
    run run_ci 'bats'
    [ "$status" -eq 0 ]
}

@test "run_ci_bats_fail()" {
    local bats_fail_file="$BATS_TEST_DIRNAME/test_fail.bats.sample"

    cp "$bats_fail_file" "$test_file"
    run run_ci 'bats'
    [ "$status" -ne 0 ]
}

@test "run_ci_black_pass()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
pass
EOF
    run run_ci 'black'
    [ "$status" -eq 0 ]
}

@test "run_ci_black_fail()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
l = ["very", "very", "long", "long", "long", "list", "list", "list", "list", "list"]
EOF
    run run_ci 'black'
    [ "$status" -ne 0 ]
}

@test "run_ci_isort_pass()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
import re
import string
EOF
    run run_ci 'isort'
    [ "$status" -eq 0 ]
}

@test "run_ci_isort_fail()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
import string
import re
EOF
    run run_ci 'isort'
    [ "$status" -ne 0 ]
}

@test "run_ci_markdown_pass()" {
    cat <<"EOF" >"$test_file"
# git-hooks
EOF
    run run_ci 'markdown'
    [ "$status" -eq 0 ]

}

@test "run_ci_markdown_fail()" {
    cat <<"EOF" >"$test_file"
# git-hooks

EOF
    run run_ci 'markdown'
    [ "$status" -ne 0 ]
}

@test "run_ci_mypy_pass()" {
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
}

@test "run_ci_mypy_fail()" {
    prepend_venv_bin_to_path

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

@test "run_ci_pylint_pass()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
EOF
    run run_ci 'pylint'
    [ "$status" -eq 0 ]
}

@test "run_ci_pylint_fail()" {
    prepend_venv_bin_to_path

    cat <<"EOF" >"$test_file"
pass
EOF
    run run_ci 'pylint'
    [ "$status" -ne 0 ]
}

@test "run_ci_python_unittest_empty()" {
    cd "$BATS_TMPDIR"
    run run_ci_python_unittest
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [ "$output" == 'unittest tests directory not found' ]
}

@test "run_ci_python_unittest_pass()" {
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
}

@test "run_ci_python_unittest_fail()" {
    prepend_venv_bin_to_path

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

@test "run_ci_shellcheck_pass()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo "Hello"
EOF
    run run_ci 'shellcheck'
    [ "$status" -eq 0 ]
}

@test "run_ci_shellcheck_fail()" {

    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo "Hello\n"
EOF
    run run_ci 'shellcheck'
    [ "$status" -ne 0 ]
}

@test "run_ci_shfmt_pass()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo 'Hello'
EOF
    run run_ci 'shfmt'
    [ "$status" -eq 0 ]
}

@test "run_ci_shfmt_fail()" {

    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

 echo 'Hello'
EOF
    run run_ci 'shfmt'
    [ "$status" -ne 0 ]
}

@test "set_git_hooks_working_dir_current_repo()" {
    declare -g git_hooks_working_dir # To clear shellcheck SC2154

    run set_git_hooks_working_dir
    [ "$status" -eq 0 ]
    [[ "$git_hooks_working_dir" == *'/git-hooks' ]]
}

@test "set_git_hooks_working_dir_submodule_repo()" {
    cd "$BATS_TMPDIR"
    mkdir "$BATS_TMPDIR/git-hooks"
    run set_git_hooks_working_dir
    rm -r './git-hooks'
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
}

@test "set_git_hooks_working_dir_fail()" {
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

teardown_file() {
    if [[ -f "$test_file" ]]; then
        rm "$test_file"
    fi
    if [[ -f "$py_test_file" ]]; then
        rm "$py_test_file"
    fi
}
