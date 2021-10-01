# Environment variables should be used for authentication.
#
# subscription_id = ARM_SUBSCRIPTION_ID
# client_id       = ARM_CLIENT_ID
# client_secret   = ARM_CLIENT_SECRET
# tenant_id       = ARM_TENANT_ID
#
# Reference the Azure Provider documentation for more information.  

provider azurerm {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

locals {
  secrets = [
    {
      key   = "${module.storage_account.name}-connection-string"
      value = module.storage_account.connection_string
    }
  ]
}

module resource_group {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.resource-group?ref=v1.0.0"

  info = var.info
  tags = var.tags

  location = var.location
}

module storage_account {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.storage-account?ref=v2.0.0"

  info = var.info
  tags = var.tags

  resource_group = module.resource_group.name
  location       = module.resource_group.location

  subnet_whitelist         = var.subnet_whitelist
  private_endpoint_enabled = false
}

module data_factory {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.data-factory?ref=v2.2.0"

  info = var.info
  tags = var.tags

  resource_group = module.resource_group.name
  location       = module.resource_group.location

  arm_template_path   = abspath("../arm-templates")
  arm_parameters_file = abspath("../arm-templates/environments/dev.parameters.json")

  private_endpoint_resources_enabled = []

  subnet_whitelist        = var.subnet_whitelist
  virtual_machine_enabled = false

  secrets = local.secrets

  arm_parameters = {
    storageAccount       = module.storage_account.name
    storageAccountSecret = "${module.storage_account.name}-connection-string"
  }
}