#!/usr/bin/env bash

get_first_env_var() {
    local env_file="$1"
    local env_name="$2"

    grep --max-count=1 "$env_name=" "$env_file"
}

prepend_venv_bin_to_path() {
    if [[ "$GITHUB_ACTIONS" == 'true' ]]; then
        echo 'Skip prepend venv bin to Path as running from GitHub Actions'
        return
    fi

    if [[ -d './venv/bin' ]]; then
        PATH="./venv/bin:$PATH"
    elif [[ -d './venv/Scripts' ]]; then
        PATH="./venv/Scripts:$PATH"
    else
        echo 'Cannot find venv binary directory'
        exit 1
    fi
}

print_files() {
    local files=("$@")

    echo '##################################################'
    echo 'Files to check:'
    for file in "${files[@]}"; do
        echo "$file"
    done
    echo '##################################################'
    echo ''
}

run_ci() {
    local choice="$1"

    echo "Running $choice"

    case "$choice" in
        'shfmt' | 'shfmt_write')
            local language='BASH'
            ;;
        'shfmt_test' | 'shfmt_write_test' | 'bats')
            local language='BASH_TEST'
            ;;
        'shellcheck')
            local language='BASH_BOTH'
            ;;
        'black' | 'black_write' | 'mypy')
            local language='PYTHON_BOTH'
            ;;
        'pylint')
            local language='PYTHON'
            ;;
        'pylint_test')
            local language='PYTHON_TEST'
            ;;
    esac

    local files_raw
    files_raw="$(python './src/filter_git_files.py' "$language")"
    mapfile -t files <<<"${files_raw//$'\r'/}"
    print_files "${files[@]}"

    case "$choice" in
        'shfmt')
            shfmt --diff --language-dialect 'bash' --indent 4 --case-indent \
                "${files[@]}"
            ;;
        'shfmt_test')
            shfmt --diff --language-dialect 'bats' --indent 4 --case-indent \
                "${files[@]}"
            ;;
        'shfmt_write')
            shfmt --write --language-dialect 'bash' --indent 4 --case-indent \
                "${files[@]}"
            ;;
        'shfmt_write_test')
            shfmt --write --language-dialect 'bats' --indent 4 --case-indent \
                "${files[@]}"
            ;;
        'shellcheck')
            shellcheck --shell=bash "${files[@]}"
            ;;
        'bats')
            for file in "${files[@]}"; do
                bats "$file"
            done
            ;;
        'black')
            black --check --diff --config './config/pyproject.toml' "${files[@]}"
            ;;
        'black_write')
            black --config './config/pyproject.toml' "${files[@]}"
            ;;
        'pylint')
            for file in "${files[@]}"; do
                pylint --rcfile './config/pylintrc.toml' "$file"
            done
            ;;
        'pylint_test')
            for file in "${files[@]}"; do
                env "$(get_first_env_var .'/.env' 'PYTHONPATH')" \
                    pylint --rcfile './config/pylintrc_test.toml' "$file"
            done
            ;;
        'mypy')
            env "$(get_first_env_var './.env' 'PYTHONPATH')" \
                mypy --config-file './config/mypy.ini' "${files[@]}"
            ;;
    esac
}

run_ci_bash() {
    run_ci_bash_shfmt
    run_ci_bash_shellcheck
    run_ci_bash_bats
}

run_ci_bash_bats() {
    run_ci 'bats'
}

run_ci_bash_shellcheck() {
    run_ci 'shellcheck'
}

run_ci_bash_shfmt() {
    run_ci 'shfmt'
    run_ci 'shfmt_test'
}

run_ci_bash_shfmt_write() {
    run_ci 'shfmt_write'
    run_ci 'shfmt_write_test'
}

run_ci_python() {
    prepend_venv_bin_to_path
    run_ci_python_black
    run_ci_python_pylint
    run_ci_python_mypy
}

run_ci_python_black() {
    run_ci 'black'
}

run_ci_python_black_write() {
    run_ci 'black_write'
}

run_ci_python_mypy() {
    run_ci 'mypy'
}

run_ci_python_pylint() {
    run_ci 'pylint'
    run_ci 'pylint_test'
}
