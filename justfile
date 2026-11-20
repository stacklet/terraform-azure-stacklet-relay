_:
    @just --list --unsorted

# format terraform files
format:
    terraform fmt -recursive

# lint files
lint:
    prek run --all-files

# update module documentation in README
docs:
    # --recursive covers examples/ as well as the root module. It cannot live in
    # .terraform-docs.yml: validate-min-terraform runs terraform-docs over a
    # read-only mount with --output-file '' to read the Terraform floor, and
    # terraform-docs rejects that combination with --recursive. Keep this in
    # step with the lint-docs job in .github/workflows/ci.yml.
    terraform-docs --recursive --recursive-path examples .
