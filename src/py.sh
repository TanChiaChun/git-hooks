#!/usr/bin/env bash

get_venv_bin_path() {
    local start_dir="$1"

    if [[ -d "$start_dir/venv/bin" ]]; then
        echo "$start_dir/venv/bin"
    elif [[ -d "$start_dir/venv/Scripts" ]]; then
        echo "$start_dir/venv/Scripts"
    fi
}
