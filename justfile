_:
    @just --list --unsorted

# format terraform files
format:
    terraform fmt -recursive

# lint files
lint:
    #!/usr/bin/env bash
    set -e

    terraform fmt -recursive --check
    terraform init
    terraform validate
    tflint -f compact --recursive

# update module documentation in README
docs:
    terraform-docs .
