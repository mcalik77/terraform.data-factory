resource azurerm_data_factory data_factory {
  name = replace(
    format("%s%s%03d",
      substr(
        module.naming.data_factory.name, 0, 
        module.naming.data_factory.max_length - 4
      ),
      substr(title(var.info.environment), 0, 1),
      title(var.info.sequence)
    ), "-", ""
  )

  resource_group_name = var.resource_group
  location            = var.location

  public_network_enabled = local.private_endpoint_resources["datafactory"] ? false : true

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}