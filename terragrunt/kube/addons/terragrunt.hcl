#https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#terraform
terraform {
  source = "../../${path_relative_to_include("root")}"
}

include {
  path = find_in_parent_folders("root.hcl")
}

dependency "kube" {
  config_path = "../"
}
