setup() {
    load '../src/ci.sh'

    export test_file="$BATS_TMPDIR/test"
    prepend_venv_bin_to_path
}

teardown() {
    if [[ -f "$test_file" ]]; then
        rm "$test_file"
    fi
}

@test "shfmt_pass()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo 'Hello'
EOF
    run run_ci 'shfmt'
    [ "$status" -eq 0 ]
}

@test "shfmt_fail()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

 echo 'Hello'
EOF
    run run_ci 'shfmt'
    [ "$status" -ne 0 ]
}

@test "shellcheck_pass()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo "Hello"
EOF
    run run_ci 'shellcheck'
    [ "$status" -eq 0 ]
}

@test "shellcheck_fail()" {
    cat <<"EOF" >"$test_file"
#!/usr/bin/env bash

echo "Hello\n"
EOF
    run run_ci 'shellcheck'
    [ "$status" -ne 0 ]
}

@test "bats_pass()" {
    local bats_pass_file="$BATS_TEST_DIRNAME/test_pass.bats.sample"

    cp "$bats_pass_file" "$test_file"
    run run_ci 'bats'
    [ "$status" -eq 0 ]
}

@test "bats_fail()" {
    local bats_fail_file="$BATS_TEST_DIRNAME/test_fail.bats.sample"

    cp "$bats_fail_file" "$test_file"
    run run_ci 'bats'
    [ "$status" -ne 0 ]
}

@test "black_pass()" {
    cat <<"EOF" >"$test_file"
pass
EOF
    run run_ci 'black'
    [ "$status" -eq 0 ]
}

@test "black_fail()" {
    cat <<"EOF" >"$test_file"
l = ["very", "very", "long", "long", "long", "list", "list", "list", "list", "list"]
EOF
    run run_ci 'black'
    [ "$status" -ne 0 ]
}

@test "pylint_pass()" {
    cat <<"EOF" >"$test_file"
EOF
    run run_ci 'pylint'
    [ "$status" -eq 0 ]
}

@test "pylint_fail()" {
    cat <<"EOF" >"$test_file"
pass
EOF
    run run_ci 'pylint'
    [ "$status" -ne 0 ]
}

@test "mypy_pass()" {
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

@test "mypy_fail()" {
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

@test "isort_pass()" {
    cat <<"EOF" >"$test_file"
import re
import string
EOF
    run run_ci 'isort'
    [ "$status" -eq 0 ]
}

@test "isort_fail()" {
    cat <<"EOF" >"$test_file"
import string
import re
EOF
    run run_ci 'isort'
    [ "$status" -ne 0 ]
}

@test "markdown_pass()" {
    cat <<"EOF" >"$test_file"
# git-hooks
EOF
    run run_ci 'markdown'
    [ "$status" -eq 0 ]

}

@test "markdown_fail()" {
    cat <<"EOF" >"$test_file"
# git-hooks

EOF
    run run_ci 'markdown'
    [ "$status" -ne 0 ]
}

@test "invalid_choice()" {
    run run_ci 'invalid'
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid CI choice' ]
}
