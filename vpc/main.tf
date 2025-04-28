#https://github.com/terraform-yc-modules/terraform-yc-kubernetes/blob/master/variables.tf

provider "yandex" {
  folder_id = var.folder_id
  zone      = var.yds_region
}

module "yc-vpc" {
  source              = "github.com/terraform-yc-modules/terraform-yc-vpc.git"
  network_name        = "test-module-network"
  network_description = "Test network created with module"
  private_subnets = [
    {
      name           = "subnet"
      zone           = var.yds_region
      v4_cidr_blocks = ["10.10.0.0/24"]
    }
  ]
}
