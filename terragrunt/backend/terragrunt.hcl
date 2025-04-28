#https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#terraform
terraform {
  source            = "${get_repo_root()}/${path_relative_to_include("root")}"
  exclude_from_copy = ["ydb/"]
}

include {
  path = find_in_parent_folders("root.hcl")
}
