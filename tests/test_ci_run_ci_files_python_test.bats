setup() {
    load '../src/ci.sh'
}

@test "django_invalid_choice()" {
    run run_ci_python_test_django 'invalid'
    [ "$status" -eq 1 ]
    [ "$output" == 'Invalid django test choice' ]
}
