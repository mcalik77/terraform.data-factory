locals {
  linked_arm_templates = "${var.arm_template_path}/linked-templates"
  arm_container        = "arm-templates"
}

module storage_account {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.storage-account?ref=v2.1.1"

  info = var.info
  tags = local.tags

  resource_group = var.resource_group
  location       = var.location

  private_endpoint_enabled = false

  random_name_enabled   = true
  network_rules_enabled = false
  container_names       = [local.arm_container]

  file_mapping = [
    {
      path      = local.linked_arm_templates
      pattern   = "**"
      container = local.arm_container
    }
  ]
}
