#!/usr/bin/env bash

is_django_project() {
    if [[ -z "$(get_first_env_var './.env' 'MY_DJANGO_PROJECT')" ]]; then
        return 1
    fi
}

set_django_env_var() {
    local django_dir
    if ! django_dir="$(get_env_value \
        "$(get_first_env_var './.env' 'MY_DJANGO_PROJECT')")"; then
        echo 'Django environment variables not set'
        return 1
    fi

    local env_line
    if ! env_line="$(grep --max-count=1 'DJANGO_SETTINGS_MODULE' \
        "$django_dir/manage.py")"; then
        echo 'Django environment variables not set'
        return 1
    fi

    [[ "$env_line" =~ [^'"']+'"'([^'"']+)'"'[^'"']+'"'([^'"']+)'"' ]]
    if [[ "${#BASH_REMATCH[@]}" -ne 3 ]]; then
        echo 'Django environment variables not set'
        return 1
    fi
    local key="${BASH_REMATCH[1]}"
    local value="${BASH_REMATCH[2]}"

    export "$key"="$value"
    echo "Set $key to $value"
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
