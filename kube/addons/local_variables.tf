variable "kube_addons_rancher_bootstrap_password" {
  type        = string
  description = "rancher bootstrap password"
  //complex regexp is not supported - https://github.com/google/re2/wiki/Syntax
  //condition = can(regex("^.*(?=.{8,})(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!#$%&? \"']).*$", var.kube_addons_rancher_bootstrap_password))
  //condition = can(regex("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@#$%^&-+=()!? '\"]).{8,128}$", var.kube_addons_rancher_bootstrap_password))
  //use 3 rules
  validation {
    condition     = can(regex("^.{8,128}$", var.kube_addons_rancher_bootstrap_password))
    error_message = "The rancher bootstrap password must be more than 8 symbols with digits and spec #$%&? \""
  }

  validation {
    condition     = can(regex("^.*(?:(?:[a-z]+.*[A-Z]+.*)|(?:.*[A-Z]+.*[a-z]+)).*$", var.kube_addons_rancher_bootstrap_password))
    error_message = "The rancher bootstrap password must be more than 8 symbols with digits and spec #$%&? \""
  }

  validation {
    condition     = can(regex("^.*(?:(?:[0-9]+.*[@#$%^&-+=()!? '\"]+)|(?:[@#$%^&-+=()!? '\"]+.*[0-9]+)).*$", var.kube_addons_rancher_bootstrap_password))
    error_message = "The rancher bootstrap password must be more than 8 symbols with digits and spec #$%&? \""
  }
}
