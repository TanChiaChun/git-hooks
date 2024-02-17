#!/usr/bin/env bash

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
