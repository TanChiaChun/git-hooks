setup() {
    load ../src/pre-commit
}

@test "reject_commit_main_branch()" {
    run reject_commit_main_branch 'main'
    [ "$status" -eq 0 ]
    [ "$output" == 'Cannot commit to main branch.' ]
}
