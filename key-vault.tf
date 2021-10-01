locals {
  key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  ip_addresses = [
    for ip in var.ip_whitelist :
      length(regexall("/", ip)) > 0 ? ip : format("%s%s", ip, "/32")
  ]

   managed_identities = concat(var.managed_identities, [
     {
        principal_name = azurerm_data_factory.data_factory.name // app name 
     }
  ])
}

module key_vault {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.key-vault?ref=v3.0.0"

  info = var.info
  tags = var.tags

  resource_group_name = var.resource_group
  location            = var.location

  sku = "standard"

  ip_rules_list    = local.ip_addresses
  subnet_whitelist = var.subnet_whitelist

  managed_identities = local.managed_identities

  private_endpoint_enabled = local.private_endpoint_resources["keyvault"]

  private_endpoint_subnet = var.private_endpoint_subnet
  secrets_list            = var.secrets

  depends_on = [azurerm_data_factory.data_factory]
}
