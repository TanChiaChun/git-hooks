#!/usr/bin/env bash

add_wd() {
    # add_working_directory
    local filepath="$1"

    if [[ "$filepath" == '.'* ]] || [[ "$filepath" == '/'* ]]; then
        echo 'Path should not start with . or /'
        exit 1
    fi

    echo "$git_hooks_working_dir/$filepath"
}

echo_red_text() {
    local text="$1"
    declare -r RED_CODE=31
    declare -r RESET_CODE=0

    echo -e "\e[${RED_CODE}m$text\e[${RESET_CODE}m"
}

get_first_env_var() {
    local env_file="$1"
    local env_name="$2"

    grep --max-count=1 "$env_name=" "$env_file"
}

handle_ci_fail() {
    local ci="$1"

    echo_red_text '##################################################'
    echo_red_text "$ci fail"
    echo_red_text '##################################################'

    return 1 # For fail-fast behavior of set -o errexit & pipefail
}

has_python_files() {
    local files_raw
    files_raw="$(python "$(add_wd 'src/filter_git_files.py')" 'PYTHON_BOTH')"
    mapfile -t files <<<"${files_raw//$'\r'/}"

    if [[ "${files[*]}" == '' ]]; then
        echo "python no files"
        return 1
    fi
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
        return 1
    fi
}

run_ci() {
    local choice="$1"

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
        'black' | 'black_write' | 'mypy' | 'isort' | 'isort_write')
            local language='PYTHON_BOTH'
            ;;
        'pylint')
            local language='PYTHON'
            ;;
        'pylint_test')
            local language='PYTHON_TEST'
            ;;
        'markdown' | 'markdown_write')
            local language='MARKDOWN'
            ;;
    esac

    local files_raw
    files_raw="$(python "$(add_wd 'src/filter_git_files.py')" "$language")"
    mapfile -t files <<<"${files_raw//$'\r'/}"

    if [[ "${files[*]}" == '' ]]; then
        echo "$choice no files"
        return
    fi

    echo '##################################################'
    echo "Running $choice"
    for file in "${files[@]}"; do
        echo "$file"
    done
    echo '##################################################'

    local is_error=0
    case "$choice" in
        'shfmt')
            if ! shfmt --diff --language-dialect 'bash' --indent 4 \
                --case-indent "${files[@]}"; then
                is_error=1
            fi
            ;;
        'shfmt_test')
            if ! shfmt --diff --language-dialect 'bats' --indent 4 \
                --case-indent "${files[@]}"; then
                is_error=1
            fi
            ;;
        'shfmt_write')
            if ! shfmt --write --language-dialect 'bash' --indent 4 \
                --case-indent "${files[@]}"; then
                is_error=1
            fi
            ;;
        'shfmt_write_test')
            if ! shfmt --write --language-dialect 'bats' --indent 4 \
                --case-indent "${files[@]}"; then
                is_error=1
            fi
            ;;
        'shellcheck')
            if ! shellcheck --shell=bash "${files[@]}"; then
                is_error=1
            fi
            ;;
        'bats')
            for file in "${files[@]}"; do
                if ! bats "$file"; then
                    is_error=1
                fi
            done
            ;;
        'black')
            if ! black --check --diff --config \
                "$(add_wd 'config/pyproject.toml')" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'black_write')
            if ! black --config "$(add_wd 'config/pyproject.toml')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'pylint')
            for file in "${files[@]}"; do
                if ! pylint --rcfile "$(add_wd 'config/pylintrc.toml')" \
                    "$file"; then
                    is_error=1
                fi
            done
            ;;
        'pylint_test')
            for file in "${files[@]}"; do
                if ! env "$(get_first_env_var './.env' 'PYTHONPATH')" \
                    pylint --rcfile "$(add_wd 'config/pylintrc_test.toml')" \
                    "$file"; then
                    is_error=1
                fi
            done
            ;;
        'mypy')
            if ! env "$(get_first_env_var './.env' 'PYTHONPATH')" \
                mypy --config-file "$(add_wd 'config/mypy.ini')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'isort')
            if ! isort --diff --check-only "${files[@]}"; then
                is_error=1
            fi
            ;;
        'isort_write')
            if ! isort "${files[@]}"; then
                is_error=1
            fi
            ;;
        'markdown')
            if ! markdownlint --config \
                "$(add_wd 'config/.markdownlint.jsonc')" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'markdown_write')
            if ! markdownlint --config \
                "$(add_wd 'config/.markdownlint.jsonc')" --fix \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
    esac

    if [[ "$is_error" -eq 1 ]]; then
        handle_ci_fail "$choice"
    fi
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

run_ci_markdown() {
    run_ci 'markdown'
}

run_ci_markdown_write() {
    run_ci 'markdown_write'
}

run_ci_python() {
    if [[ -d './venv' ]]; then
        prepend_venv_bin_to_path
        run_ci_python_black
        run_ci_python_pylint
        run_ci_python_mypy
        run_ci_python_isort
        run_ci_python_unittest
    else
        if (has_python_files); then
            return 1
        fi
    fi
}

run_ci_python_black() {
    run_ci 'black'
}

run_ci_python_black_write() {
    run_ci 'black_write'
}

run_ci_python_isort() {
    run_ci 'isort'
}

run_ci_python_isort_write() {
    run_ci 'isort_write'
}

run_ci_python_mypy() {
    run_ci 'mypy'
}

run_ci_python_pylint() {
    run_ci 'pylint'
    run_ci 'pylint_test'
}

run_ci_python_unittest() {
    echo '##################################################'
    echo 'Running unittest'
    echo '##################################################'

    options_raw="$(python "$(add_wd 'src/get_unittest_options.py')")"
    mapfile -t options <<<"${options_raw//$'\r'/}"

    if ! env "$(get_first_env_var './.env' 'PYTHONPATH')" \
        python -m unittest "${options[@]}"; then
        handle_ci_fail 'unittest'
    fi
}

set_git_hooks_working_dir() {
    if [[ "$PWD" == *'/git-hooks' ]]; then
        git_hooks_working_dir="$PWD"
    elif [[ -d './git-hooks' ]]; then
        git_hooks_working_dir="$PWD/git-hooks"
    else
        echo 'Unsupported git-hooks working directory'
        return 1
    fi

    echo "Set git-hooks working directory to '$git_hooks_working_dir'"
}

main() {
    if ! set_git_hooks_working_dir; then
        return 1
    fi
}

main
