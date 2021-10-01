locals {
  private_endpoint_resources = merge(
    {
      datafactory = false
      keyvault    = false
    },
    {
      for resource in var.private_endpoint_resources_enabled :
        lower(resource) => true
    }
  )
}

module private_endpoint {
  count = local.private_endpoint_resources["datafactory"] ? 1 : 0

  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.private-endpoint?ref=v0.0.6"

  info = var.info
  tags = local.tags

  resource_group_name = var.resource_group
  location            = var.location

  resource_id       = azurerm_data_factory.data_factory.id
  subresource_names = ["dataFactory", "portal"]

  private_endpoint_subnet = var.private_endpoint_subnet
}

resource null_resource approve_private_endpoints {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      PRIVATE_LINKS=`
        az network private-endpoint list \
          --resource-group "${var.resource_group}" \
          --query "[].privateLinkServiceConnections[?!(contains(privateLinkServiceId, 'Microsoft.DataFactory'))][].privateLinkServiceId" \
          --output tsv
      `

      for private_link in $PRIVATE_LINKS; do
        CONNECTION_ID=`
          az network private-endpoint-connection list \
            --id $private_link \
            --query "[?properties.privateLinkServiceConnectionState.status == 'Pending'].id" \
            --output tsv
        `

        [[ -z $CONNECTION_ID ]] && continue

        az network private-endpoint-connection approve \
          --id $CONNECTION_ID \
          --description "Approved"
      done
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [null_resource.deploy_arm_templates]
}