# Environment variables should be used for authentication.
#
# ARM_SUBSCRIPTION_ID
# ARM_CLIENT_ID
# ARM_CLIENT_SECRET
# ARM_TENANT_ID
#
# Reference the Azure Provider documentation for more information.
terraform {
  experiments = [module_variable_optional_attrs]
}

variable info {
  type = object({
    domain      = string
    subdomain   = string
    environment = string
    sequence    = string
    vm_infix    = string
  })

  description = "Info object used to construct naming convention for data factory."
}

variable tags {
  type        = map(string)
  description = "Tags object used to tag data factory."
}

variable resource_group {
  type        = string
  description = "Name of the resource group where the data factory will be deployed."
}

variable location {
  type        = string
  description = "Region where all the resources of the data factory will be created."
}

variable arm_template_path {
  type        = string
  description = "Absolute path of the ARM templates to upload."
}

variable arm_parameters_file {
  type        = string
  description = "Absolute path of the ARM paramters file to use in the deployment."

  default = ""
}

variable arm_parameters {
  type        = map(string)
  description = "Object containing parameters for the ARM templates."

  default = {}
}

variable triggers_enabled {
  type        = bool
  description = "Determines if the data factory triggers should be enabled on deployment."

  default = true
}

variable secrets {
  type        = list(map(string))
  description = "List of objects containing attributes for a secret to add to the key vault."

  default = []
}

variable ip_whitelist {
  type        = list(string)
  description = "List of public IP or IP ranges in CIDR Format to allow."

  default = []
}

variable subnet_whitelist {
  type = list(object({
    virtual_network_resource_group_name = string
    virtual_network_name                = string
    virtual_network_subnet_name         = string
  }))

  description = "List of objects that contains information to look up a subnet. This is a whitelist of subnets to allow for the key vault."
  default     = []
}

variable virtual_machine_enabled {
  type        = bool
  description = "Determines if the integration runtime virtual machine should be created."

  default = true
}

variable virtual_machine_size {
  type        = string
  description = "SKU used for provisioning the virtual machine."

  default = "Standard_F4s_v2"
}

variable virtual_machine_storage {
  type        = string
  description = "Type of storage account used for the OS disk."

  default = "StandardSSD_LRS"
}

variable virtual_machine_packages {
  type        = list(string)
  description = "A list of packages to install in the virtual machine."

  default = []

  validation {
    condition = length([
      for resource in var.virtual_machine_packages : true

      if lower(resource) == "odbc"

    ]) > 0 || length(var.virtual_machine_packages) == 0

    error_message = "Value must be one of ['odbc']."
  }
}

variable ip_address_type {
  type        = string
  description = "The allocation method used for the IP address."

  default = "Static"
}

variable virtual_machine_ip_config {
  type = object({
    virtual_network = string
    subnet          = string
    resource_group  = string
    ip_address      = string
  })

  description = "Virtual machine IP address configuration."

  default = {
    virtual_network = null
    subnet          = null
    resource_group  = null
    ip_address      = null
  }
}

variable ad_password {
  type        = string
  description = "Password used to join the active directory domain."
}

variable private_endpoint_resources_enabled {
  type        = list(string)
  description = "Determines if private endpoint should be enabled for specific resources."

  default = ["datafactory", "keyvault"]

  validation {
    condition = length([
      for resource in var.private_endpoint_resources_enabled : true

      if lower(resource) == "datafactory" ||
         lower(resource) == "keyvault"

    ]) > 0 || length(var.private_endpoint_resources_enabled) == 0

    error_message = "Value must be one of ['datafactory', 'keyvault']."
  }
}

variable private_endpoint_subnet {
  type = object({
    virtual_network_name                = string
    virtual_network_subnet_name         = string
    virtual_network_resource_group_name = string
  })

  description = "Object that contains information to lookup the subnet to use for the privat endpoint."

  default = {
    virtual_network_name                = null
    virtual_network_subnet_name         = null
    virtual_network_resource_group_name = null
  }
}

variable destroy_arm_on_deployment {
  type        = bool
  description = "Determines if resources deployed from ARM templates should be destroyed on deployment?"

  default = false
}

variable managed_identities {
  type = list(object({
    principal_name = string
    roles          = optional(list(string))
  }))
  description = "The name of manage identities(Service principal or Application name) to give key-vault access"
}