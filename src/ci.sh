#!/usr/bin/env bash

echo_red_text() {
    local text="$1"
    declare -r RED_CODE=31
    declare -r RESET_CODE=0

    echo -e "\e[${RED_CODE}m$text\e[${RESET_CODE}m"
}

get_current_script_dir() {
    local current_script_path
    current_script_path="$(readlink -f "${BASH_SOURCE[0]}")"

    get_parent_dir "$current_script_path"
}

get_env_value() {
    local env_line="$1"

    if [[ "$env_line" =~ .+'='.+ ]]; then
        echo "${env_line#*=}"
    else
        echo 'Invalid env line'
        return 1
    fi

}

get_first_env_var() {
    local env_file="$1"
    local env_name="$2"

    grep --max-count=1 "$env_name=" "$env_file"
}

get_parent_dir() {
    local file_path="$1"

    echo "${file_path%/*}"
}

get_pythonpath_value() {
    local env_line
    env_line="$(get_first_env_var './.env' 'PYTHONPATH')"
    local env_value
    if ! env_value="$(get_env_value "$env_line")"; then
        echo 'Invalid env line'
        return 1
    fi

    if [[ ("$env_value" == *':'*) || ("$env_value" == *';'*) ]]; then
        echo 'Multiple PYTHONPATH directories not supported for isort'
        return 1
    fi

    echo "$env_value"
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
    files_raw="$(python "$(update_path 'src/filter_git_files.py')" \
        'PYTHON_BOTH')"
    mapfile -t files <<<"${files_raw//$'\r'/}"

    if [[ "${files[*]}" == '' ]]; then
        return 1
    fi
}

prepend_venv_bin_to_path() {
    if [[ "$GITHUB_ACTIONS" == 'true' ]]; then
        echo 'Skip prepend venv bin to Path as running from GitHub Actions'
        return
    fi

    local venv_bin_path
    venv_bin_path="$(get_venv_bin_path '.')"
    if [[ -z "$venv_bin_path" ]]; then
        echo 'Cannot find venv binary directory'
        return 1
    fi

    PATH="$venv_bin_path:$PATH"
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
    files_raw="$(python "$(update_path 'src/filter_git_files.py')" "$language")"
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
                "$(update_path 'config/pyproject.toml')" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'black_write')
            if ! black --config "$(update_path 'config/pyproject.toml')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'pylint')
            for file in "${files[@]}"; do
                if ! env "$(get_first_env_var './.env' 'PYTHONPATH')" pylint \
                    --rcfile "$(update_path 'config/pylintrc.toml')" \
                    "$file"; then
                    is_error=1
                fi
            done
            ;;
        'pylint_test')
            for file in "${files[@]}"; do
                if ! env "$(get_first_env_var './.env' 'PYTHONPATH')" pylint \
                    --rcfile "$(update_path 'config/pylintrc_test.toml')" \
                    "$file"; then
                    is_error=1
                fi
            done
            ;;
        'mypy')
            if ! env "$(get_first_env_var './.env' 'PYTHONPATH')" \
                mypy --config-file "$(update_path 'config/mypy.ini')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'isort')
            if ! isort --src-path "$(get_pythonpath_value)" --diff \
                --check-only \
                --settings-path "$(update_path 'config/.isort.cfg')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'isort_write')
            if ! isort --src-path "$(get_pythonpath_value)" \
                --settings-path "$(update_path 'config/.isort.cfg')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'markdown')
            if ! markdownlint --config \
                "$(update_path 'config/.markdownlint.jsonc')" \
                "${files[@]}"; then
                is_error=1
            fi
            ;;
        'markdown_write')
            if ! markdownlint --config \
                "$(update_path 'config/.markdownlint.jsonc')" --fix \
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
            echo "python files found, but venv not created"
            return 1
        else
            echo "python no files"
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
    if [[ ! -d ./tests ]]; then
        echo 'unittest tests directory not found'
        return
    fi

    echo '##################################################'
    echo 'Running unittest'
    echo '##################################################'

    options_raw="$(python "$(update_path 'src/get_unittest_options.py')")"
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

source_py_sh() {
    local py_sh_path
    py_sh_path="$(get_current_script_dir)/py.sh"

    if [[ ! -f "$py_sh_path" ]]; then
        echo "$py_sh_path not found"
        return 1
    fi

    # shellcheck source=/dev/null
    source "$py_sh_path"
}

update_path() {
    local filepath="$1"

    if [[ "$filepath" == '.'* ]] || [[ "$filepath" == '/'* ]]; then
        echo 'Path should not start with . or /'
        exit 1
    fi

    local dir="$git_hooks_working_dir"
    if [[ -f "./$filepath" ]]; then
        dir='.'
    fi

    echo "$dir/$filepath"
}

main() {
    if ! source_py_sh; then
        return 1
    fi
    if ! set_git_hooks_working_dir; then
        return 1
    fi
}

main
