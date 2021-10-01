# Azure Data Factory

Terraform module that provisions a Data Factory on Azure using ARM templates.

# Usage

You can include the module by using the following code:

```
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
    },
    {
      key   = "ns-bazfiler02-password"
      value = var.network_share_password
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
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.storage-account?ref=v2.1.1"

  info = var.info
  tags = var.tags

  resource_group = module.resource_group.name
  location       = module.resource_group.location

  subnet_whitelist        = var.subnet_whitelist
  private_endpoint_subnet = var.private_endpoint_subnet
}

module data_factory {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.data-factory?ref=v2.3.0"

  info = var.info
  tags = var.tags

  resource_group = module.resource_group.name
  location       = module.resource_group.location

  arm_template_path   = abspath("../arm-templates")
  arm_parameters_file = abspath("../arm-templates/environments/dev.parameters.json")

  subnet_whitelist        = var.subnet_whitelist
  private_endpoint_subnet = var.private_endpoint_subnet

  virtual_machine_ip_config = var.virtual_machine_ip_config

  ad_password = var.ad_password
  secrets     = local.secrets

  arm_parameters = {
    integrationRuntime   = "irBcBsAzRuntime"
    storageAccount       = module.storage_account.name
    storageAccountSecret = "${module.storage_account.name}-connection-string"
    networkShareSecret   = "ns-bazfiler02-password"
  }
}
```

You can specify the values of the variables through a **tfvars** file or from
the command line. If needed you can even do a combination of the two by
specifying the **-var** and **-var-file** command line arguments.

## dev.tfvars

```
info = {
  domain      = "DevOps"
  subdomain   = "Sandbox"
  environment = "Dev"
  sequence    = "001"
  vm_infix    = "box"
}

tags = {
  owner = "Devops"
}

location = "South Central US"

subnet_whitelist = [
  {
    virtual_network_resource_group_name = "spokeVnetRg"
    virtual_network_name                = "vnetVelConD01"
    virtual_network_subnet_name         = "vnD01sn001"
  }
]

private_endpoint_subnet = {
  virtual_network_name                = "vnetVelConD01"
  virtual_network_subnet_name         = "privateLink01"
  virtual_network_resource_group_name = "spokeVnetRg"
}

virtual_machine_ip_config = {
  virtual_network = "vnetVelConD01"
  subnet          = "vnD01sn001"
  resource_group  = "spokeVnetRg"
  ip_address      = "10.202.128.14"
}
```

By default a virtual machine will be provisioned for running the integration
runtime. You can disable the creation of the virtual machine if needed.

## Inputs

The following are the supported inputs for the module.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| info | Info object used to construct naming convention for data factory. | `object(string)` | `n/a` | yes |
| tags | Tags object used to tag data factory. | `map(string)` | `n/a` | yes |
| resource_group | Name of the resource group where the data factory will be deployed. | `string` | `n/a` | yes |
| location | Region where all the resources of the data factory will be created. | `string` | `n/a` | yes |
| arm_template_path | Absolute path of the ARM templates to upload. | `string` | `n/a` | yes |
| arm_parameters_file | Absolute path of the ARM paramters file to use in the deployment. | `string` | `""` | no |
| arm_parameters | Object containing parameters for the ARM templates. | `map(string)` | `n/a` | yes |
| triggers_enabled | Determines if the data factory triggers should be enabled on deployment. | `bool` | `true` | no |
| secrets | List of objects containing attributes for a secret to add to the key vault. | `list(map(string))` | `[]` | yes |
| ip_whitelist | List of public IP or IP ranges in CIDR Format to allow. **Note**: prefix must be smaller than or equal to 30. Omit the prefix for single IP addresses. | `list(string)` | `[]` | no |
| subnet_whitelist | List of objects that contains information to look up a subnet. This is a whitelist of subnets to allow for the key vault. | `list(object)` | `[]` | no |
| virtual_machine_enabled | Determines if the integration runtime virtual machine should be created. | `bool` | `true` | no |
| virtual_machine_size | SKU used for provisioning the virtual machine. | `string` | `Standard_DS3_v2` | no |
| virtual_machine_storage | Type of storage account used for the OS disk. | `string` | `StandardSSD_LRS` | no |
| virtual_machine_packages | A list of packages to install in the virtual machine, supported packages: **[odbc]** | `list(string)` | `[]` | no |
| ip_address_type | The allocation method used for the IP address. | `string` | `Static` | no |
| virtual_machine_ip_config | Virtual machine IP address configuration object. When **ip_address_type** is Dynamic this variable is optional, otherwise it is **required**.  | `object(string)` | `{}` | yes |
| ad_password | Password used to join the active directory domain. When **virtual_machine_enabled** is false this variable is optional, otherwise it is **required**.  | `string` | `n/a` | yes |
| private_endpoint_resources_enabled | Determines if private endpoint should be enabled for specific resources, **[]** to disable private endpoint. | `list(string)` | `["datafactory", "keyvault"]` | no |
| private_endpoint_subnet | Object that contains information to lookup the subnet to use for the privat endpoint. When **private_endpoint_enabled** is set to true this variable is required, otherwise it is optional | `object` | n/a | no |
| destroy_arm_on_deployment | Determines if resources deployed from ARM templates should be destroyed on deployment? | `bool` | `false` | no |
