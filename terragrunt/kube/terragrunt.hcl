#https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#terraform
terraform {
  source            = "../../${path_relative_to_include("root")}"
  exclude_from_copy = ["addons/"]
}

include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
}
