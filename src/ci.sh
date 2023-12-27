#!/usr/bin/env bash

get_first_env_var() {
    local env_file="$1"
    local env_name="$2"

    grep --max-count=1 "$env_name=" "$env_file"
}

print_files() {
    local files=("$@")

    echo '##################################################'
    echo 'Files to check:'
    for file in "${files[@]}"; do
        echo "$file"
    done
    echo '##################################################'
}

run_ci() {
    local choice="$1"

    case "$choice" in
        'shfmt' | 'shfmt_write')
            local language='BASH'
            ;;
        'shfmt_test' | 'shfmt_write_test')
            local language='BASH_TEST'
            ;;
    esac

    mapfile -t files < <(python ./src/filter_git_files.py "$language")
    print_files "${files[@]}"

    case $choice in
        'shfmt')
            shfmt --diff --language-dialect bash --indent 4 --case-indent "${files[@]}"
            ;;
        'shfmt_test')
            shfmt --diff --language-dialect bats --indent 4 --case-indent "${files[@]}"
            ;;
        'shfmt_write')
            shfmt --write --language-dialect bash --indent 4 --case-indent "${files[@]}"
            ;;
        'shfmt_write_test')
            shfmt --write --language-dialect bats --indent 4 --case-indent "${files[@]}"
            ;;
    esac
}

run_ci_bash_shfmt() {
    run_ci 'shfmt'
    run_ci 'shfmt_test'
}

run_ci_bash_shfmt_write() {
    run_ci 'shfmt_write'
    run_ci 'shfmt_write_test'
}
