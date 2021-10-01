# Environment variables should be used for authentication.
#
# ARM_SUBSCRIPTION_ID
# ARM_CLIENT_ID
# ARM_CLIENT_SECRET
# ARM_TENANT_ID
#
# Reference the Azure Provider documentation for more information.

terraform {
  required_version = ">= 0.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.40.0"
    }

    http = {
      source  = "hashicorp/http"
      version = ">= 2.0.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

locals {
  domain    = title(var.info.domain)
  subdomain = title(var.info.subdomain)

  subproject = "${local.domain}${local.subdomain}"

  tags = merge(
    {
      for key, value in var.tags: key => title(value)
    }, 
    {
      subproject  = local.subproject
      environment = title(var.info.environment)
      source      = "Terraform"
    }
  )

  integration_runtime_key = (
    var.virtual_machine_enabled ?
      azurerm_template_deployment.output_ir_key[0].outputs["integrationRuntimeKey"] : null
  )
}

data http ip_address {
  url = "https://google.com"
}

module naming {
  source = "github.com/Azure/terraform-azurerm-naming?ref=64b9489"
  suffix = [local.subproject]
}

module sas_token {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.sas-token?ref=v1.0.0"

  connection_string   = module.storage_account.connection_string
  expiration_interval = "30m"
}

module virtual_machine {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.virtual-machine?ref=v1.1.0"
  count  = var.virtual_machine_enabled ? 1 : 0

  info = var.info
  tags = var.tags

  resource_group = var.resource_group
  location       = var.location

  virtual_machine_size     = var.virtual_machine_size
  virtual_machine_storage  = var.virtual_machine_storage
  virtual_machine_packages = var.virtual_machine_packages

  ip_address_type = var.ip_address_type
  ip_config       = var.virtual_machine_ip_config

  integration_runtime_enabled = var.virtual_machine_enabled

  integration_runtime_key = local.integration_runtime_key
  ad_password             = var.ad_password
}
