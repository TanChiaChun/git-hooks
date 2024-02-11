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
