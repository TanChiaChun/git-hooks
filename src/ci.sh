#!/usr/bin/env bash

get_first_env_var() {
    local env_file=$1
    local env_name=$2

    grep --max-count=1 "$env_name=" "$env_file"
}
