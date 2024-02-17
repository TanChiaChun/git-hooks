#!/usr/bin/env bash

activate_project_venv_bash() {
    # shellcheck source=/dev/null
    source "$(get_venv_bin_path '.')/activate"
}

create_project_venv() {
    if [[ -d './venv' ]]; then
        echo 'Existing venv detected'
        return
    fi

    python -m venv './venv'
}

get_venv_bin_path() {
    local start_dir="$1"

    if [[ -d "$start_dir/venv/bin" ]]; then
        echo "$start_dir/venv/bin"
    elif [[ -d "$start_dir/venv/Scripts" ]]; then
        echo "$start_dir/venv/Scripts"
    fi
}

is_django_project() {
    if [[ -z "$(get_first_env_var './.env' 'MY_DJANGO_PROJECT')" ]]; then
        return 1
    fi
}

source_helper_sh() {
    local current_script_path
    current_script_path="$(readlink -f "${BASH_SOURCE[0]}")"
    local current_script_dir="${current_script_path%/*}"

    local sh_path="$current_script_dir/helper.sh"

    if [[ ! -f "$sh_path" ]]; then
        echo "$sh_path not found"
        return 1
    fi

    # shellcheck source=/dev/null
    source "$sh_path"
}

main() {
    if ! source_helper_sh; then
        return 1
    fi
}

main
