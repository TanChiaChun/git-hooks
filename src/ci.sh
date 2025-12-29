#!/usr/bin/env bash

echo_red_text() {
    local text="$1"
    local -r RED_CODE=31
    local -r RESET_CODE=0

    echo -e "\e[${RED_CODE}m$text\e[${RESET_CODE}m"
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
    local script_path
    script_path="$(update_path 'src/git_files_filter.py')"
    local files_raw
    files_raw="$(python "$script_path" 'PYTHON_BOTH')"
    mapfile -t files <<<"${files_raw//$'\r'/}"

    if [[ -z "${files[*]}" ]]; then
        return 1
    fi
}

run_ci_dir() {
    local choice="$1"

    echo '##################################################'
    echo "Running $choice"
    echo '##################################################'

    local is_error=0
    case "$choice" in
        'bats')
            if [[ ! -d './tests' ]]; then
                echo 'bats tests directory not found'
                return
            fi

            if ! bats --print-output-on-failure './tests'; then
                is_error=1
            fi
            ;;
        'markdown')
            local config_path
            config_path="$(update_path 'config/.markdownlint-cli2.jsonc')"
            if ! markdownlint-cli2 --config "$config_path"; then
                is_error=1
            fi
            ;;
        'markdown_write')
            local config_path
            config_path="$(update_path 'config/.markdownlint-cli2.jsonc')"
            if ! markdownlint-cli2 --config "$config_path" --fix; then
                is_error=1
            fi
            ;;
        *)
            echo 'Invalid CI choice'
            return 1
            ;;
    esac

    if [[ "$is_error" -eq 1 ]]; then
        handle_ci_fail "$choice"
    fi
}

run_ci_files() {
    local choice="$1"

    case "$choice" in
        'shfmt' | 'shfmt_write')
            local language='BASH'
            ;;
        'shfmt_test' | 'shfmt_write_test')
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
        *)
            echo 'Invalid CI choice'
            return 1
            ;;
    esac

    local script_path
    script_path="$(update_path 'src/git_files_filter.py')"
    local files_raw
    files_raw="$(python "$script_path" "$language")"
    mapfile -t files <<<"${files_raw//$'\r'/}"

    if [[ -z "${files[*]}" ]]; then
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
        'black')
            local config_path
            config_path="$(update_path 'config/pyproject.toml')"
            if ! uv run \
                black --check --diff --config "$config_path" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'black_write')
            local config_path
            config_path="$(update_path 'config/pyproject.toml')"
            if ! uv run \
                black --config "$config_path" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'pylint')
            local config_path
            config_path="$(update_path 'config/pylintrc.toml')"
            for file in "${files[@]}"; do
                if ! uv run --env-file './.env' \
                    pylint --rcfile "$config_path" "$file"; then
                    is_error=1
                fi
            done
            ;;
        'pylint_test')
            local config_path
            config_path="$(update_path 'config/pylintrc_test.toml')"
            for file in "${files[@]}"; do
                if ! uv run --env-file './.env' \
                    pylint --rcfile "$config_path" "$file"; then
                    is_error=1
                fi
            done
            ;;
        'mypy')
            local config_path
            config_path="$(update_path 'config/mypy.ini')"
            if ! uv run --env-file './.env' \
                mypy --config-file "$config_path" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'isort')
            local config_path
            config_path="$(update_path 'config/.isort.cfg')"
            if ! uv run \
                isort --src-path "$(get_pythonpath_value)" --diff --check-only \
                --settings-path "$config_path" "${files[@]}"; then
                is_error=1
            fi
            ;;
        'isort_write')
            local config_path
            config_path="$(update_path 'config/.isort.cfg')"
            if ! uv run \
                isort --src-path "$(get_pythonpath_value)" \
                --settings-path "$config_path" "${files[@]}"; then
                is_error=1
            fi
            ;;
    esac

    if [[ "$is_error" -eq 1 ]]; then
        handle_ci_fail "$choice"
    fi
}

run_ci_project() {
    local choice="$1"

    echo '##################################################'
    echo "Running $choice"
    echo '##################################################'

    local is_error=0
    case "$choice" in
        'ruff_lint')
            local config_path
            config_path="$(update_path 'config/pyproject.toml')"
            if ! uv run \
                ruff check --config "$config_path"; then
                is_error=1
            fi
            ;;
        'ruff_lint_write')
            local config_path
            config_path="$(update_path 'config/pyproject.toml')"
            if ! uv run \
                ruff check --fix --config "$config_path"; then
                is_error=1
            fi
            ;;
        'pytest')
            local config_path
            config_path="$(update_path 'config/pytest.toml')"
            uv run --env-file ./.env \
                pytest --config-file="$config_path" --rootdir=.
            local exit_code=$?
            if ((exit_code == 5)); then
                echo 'No tests were collected'
                return
            elif ((exit_code != 0)); then
                is_error=1
            fi
            ;;
        'eslint')
            if ! npx eslint .; then
                is_error=1
            fi
            ;;
        'eslint_write')
            if ! npx eslint --fix .; then
                is_error=1
            fi
            ;;
        'prettier')
            config_path="$(update_path 'config/.prettierrc.json')"
            if ! npx prettier --check --config "$config_path" .; then
                is_error=1
            fi
            ;;
        'prettier_write')
            config_path="$(update_path 'config/.prettierrc.json')"
            if ! npx prettier --config "$config_path" --write .; then
                is_error=1
            fi
            ;;
        'vitest')
            if ! npx vitest run; then
                is_error=1
            fi
            ;;
        'vitest_coverage')
            if ! npx vitest run --coverage; then
                is_error=1
            fi
            ;;
        'vue-tsc')
            if ! npx vue-tsc --build; then
                is_error=1
            fi
            ;;
        *)
            echo 'Invalid CI choice'
            return 1
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
    run_ci_dir 'bats'
}

run_ci_bash_shellcheck() {
    run_ci_files 'shellcheck'
}

run_ci_bash_shfmt() {
    run_ci_files 'shfmt'
    run_ci_files 'shfmt_test'
}

run_ci_bash_shfmt_write() {
    run_ci_files 'shfmt_write'
    run_ci_files 'shfmt_write_test'
}

run_ci_markdown() {
    run_ci_dir 'markdown'
}

run_ci_markdown_write() {
    run_ci_dir 'markdown_write'
}

run_ci_python() {
    if [[ -d './.venv' ]]; then
        if (is_django_project); then
            set_django_env_var
        fi

        run_ci_python_black
        run_ci_python_ruff_lint
        run_ci_python_pylint
        run_ci_python_mypy
        run_ci_python_isort
        if (is_django_project); then
            run_ci_python_test_django_django
        else
            run_ci_python_test_unittest
        fi
    else
        if (has_python_files); then
            echo 'python files found, but venv not created'
            return 1
        else
            echo 'python no files'
        fi
    fi
}

run_ci_python_black() {
    run_ci_files 'black'
}

run_ci_python_black_write() {
    run_ci_files 'black_write'
}

run_ci_python_isort() {
    run_ci_files 'isort'
}

run_ci_python_isort_write() {
    run_ci_files 'isort_write'
}

run_ci_python_mypy() {
    run_ci_files 'mypy'
}

run_ci_python_ruff_lint() {
    run_ci_project 'ruff_lint'
}

run_ci_python_ruff_lint_write() {
    run_ci_project 'ruff_lint_write'
}

run_ci_python_pylint() {
    run_ci_files 'pylint'
    run_ci_files 'pylint_test'
}

run_ci_python_test() {
    local choice="$1"

    if [[ ! -d './tests' ]]; then
        echo 'unittest tests directory not found'
        return
    fi

    echo '##################################################'
    echo "Running $choice"
    echo '##################################################'

    local script_path
    script_path="$(update_path 'src/unittest_options.py')"
    local options_raw
    options_raw="$(python "$script_path")"
    mapfile -t options <<<"${options_raw//$'\r'/}"

    local is_error=0
    case "$choice" in
        'unittest')
            if ! uv run --env-file './.env' \
                python -m unittest "${options[@]}"; then
                is_error=1
            fi
            ;;
        'coverage_py')
            local config_path
            config_path="$(update_path 'config/.coveragerc')"
            if uv run --env-file './.env' \
                coverage run --rcfile="$config_path" \
                -m unittest "${options[@]}"; then
                uv run \
                    coverage html
            else
                is_error=1
            fi
            ;;
        *)
            echo 'Invalid test choice'
            return 1
            ;;
    esac

    if [[ "$is_error" -eq 1 ]]; then
        handle_ci_fail "$choice"
    fi
}

run_ci_python_test_coverage_py() {
    if (is_django_project); then
        run_ci_python_test_django 'coverage_py'
    else
        run_ci_python_test 'coverage_py'
    fi
}

run_ci_python_test_django() {
    local choice="$1"

    local test_name
    case "$choice" in
        'django')
            test_name='Django test'
            ;;
        'coverage_py')
            test_name='Django test - Coverage.py'
            ;;
        *)
            echo 'Invalid django test choice'
            return 1
            ;;
    esac

    echo '##################################################'
    echo "Running $test_name"
    echo '##################################################'

    local django_dir
    django_dir="$(get_env_value \
        "$(get_first_env_var './.env' 'MY_DJANGO_PROJECT')")"
    cd "$django_dir" || return 1

    local is_error=0
    case "$choice" in
        'django')
            if ! uv run \
                python ./manage.py test; then
                is_error=1
            fi
            ;;
        'coverage_py')
            if uv run \
                coverage run --rcfile="$(update_path 'config/.coveragerc')" \
                --source='.' ./manage.py test; then
                uv run \
                    coverage html
            else
                is_error=1
            fi
            ;;
    esac

    cd "$OLDPWD" || exit 1

    if [[ "$is_error" -eq 1 ]]; then
        handle_ci_fail "$test_name"
    fi
}

run_ci_python_test_django_django() {
    run_ci_python_test_django 'django'
}

run_ci_python_test_unittest() {
    run_ci_python_test 'unittest'
}

run_ci_vue() {
    run_ci_vue_tsc
    run_ci_vue_prettier
    run_ci_vue_eslint
    run_ci_vue_vitest
}

run_ci_vue_eslint() {
    run_ci_project 'eslint'
}

run_ci_vue_eslint_write() {
    run_ci_project 'eslint_write'
}

run_ci_vue_prettier() {
    run_ci_project 'prettier'
}

run_ci_vue_prettier_write() {
    run_ci_project 'prettier_write'
}

run_ci_vue_vitest() {
    run_ci_project 'vitest'
}

run_ci_vue_vitest_coverage() {
    run_ci_project 'vitest_coverage'
}

run_ci_vue_tsc() {
    run_ci_project 'vue-tsc'
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

source_sh_script_dir() {
    local filename="$1"

    local current_script_path
    current_script_path="$(readlink -f "${BASH_SOURCE[0]}")"
    local current_script_dir="${current_script_path%/*}"

    local sh_path="$current_script_dir/$filename"

    if [[ ! -f "$sh_path" ]]; then
        echo "$sh_path not found"
        return 1
    fi

    # shellcheck source=/dev/null
    source "$sh_path"
}

update_path() {
    local filepath="$1"

    if [[ ("$filepath" == '.'*) || ("$filepath" == '/'*) ]]; then
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
    if ! source_sh_script_dir 'helper.sh'; then
        return 1
    fi
    if ! source_sh_script_dir 'py.sh'; then
        return 1
    fi
    if ! set_git_hooks_working_dir; then
        return 1
    fi
}

main
