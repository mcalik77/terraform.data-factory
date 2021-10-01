locals {
  arm_template = "${var.arm_template_path}/data-factory.json"

  blob_endpoint = "https://${module.storage_account.name}.blob.core.windows.net"
  arm_endpoint  = "${local.blob_endpoint}/${local.arm_container}/"

  data_factory = azurerm_data_factory.data_factory.name

  integration_runtime = lookup(var.arm_parameters, "integrationRuntime", "irSelfHosted")

  arm_parameters = merge(
    {
      armEndpoint     = local.arm_endpoint
      dataFactory     = local.data_factory
      keyVaultBaseUrl = module.key_vault.key_vault_uri
    },
    var.arm_parameters
  )
}

resource null_resource azure_login {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      az login --service-principal \
        --username $ARM_CLIENT_ID \
        --password $ARM_CLIENT_SECRET \
        --tenant $ARM_TENANT_ID
    EOF
  }

  triggers = {
    always = uuid()
  }
}

resource null_resource disable_triggers {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      TRIGGERS=`
        az datafactory trigger list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --query "[?properties.runtimeState == 'Started'].name" \
          --output tsv \
          --only-show-errors
      `

      for trigger in $TRIGGERS; do
        echo "stopping trigger $trigger..."

        az datafactory trigger stop \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --name "$trigger" \
          --only-show-errors
      done
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [null_resource.azure_login]
}

resource null_resource destroy_triggers {
  count = var.destroy_arm_on_deployment ? 1 : 0

  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      TRIGGERS=`
        az datafactory trigger list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --only-show-errors \
          --query [].name \
          --output tsv
      `

      for trigger in $TRIGGERS; do
        echo "deleting trigger $trigger..."

        az datafactory trigger delete \
          --name $trigger \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
	        --only-show-errors \
	        --yes
      done
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [null_resource.disable_triggers]
}

resource null_resource destroy_pipelines {
  count = var.destroy_arm_on_deployment ? 1 : 0

  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      PIPELINES=`
        az datafactory pipeline list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --only-show-errors \
          --query [].name \
          --output tsv
      `

      for pipeline in $PIPELINES; do
        echo "deleting pipeline $pipeline..."

        az datafactory pipeline delete \
          --name $pipeline \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
	        --only-show-errors \
	        --yes
      done
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [null_resource.destroy_triggers]
}

resource null_resource destroy_datasets {
  count = var.destroy_arm_on_deployment ? 1 : 0

  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      DATASETS=`
        az datafactory dataset list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --only-show-errors \
          --query [].name \
          --output tsv
      `

      for dataset in $DATASETS; do
        echo "deleting dataset $dataset..."

        az datafactory dataset delete \
          --name $dataset \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
	        --only-show-errors \
	        --yes
      done
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [null_resource.destroy_pipelines]
}

resource null_resource destroy_linked_services {
  count = var.destroy_arm_on_deployment ? 1 : 0

  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      LINKED_SERVICES=`
        az datafactory linked-service list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --only-show-errors \
          --query "[?properties.type != 'AzureKeyVault'].name" \
          --output tsv
      `

      KEY_VAULT=`
        az datafactory linked-service list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --only-show-errors \
          --query "[?properties.type == 'AzureKeyVault'].name" \
          --output tsv
      `

      LINKED_SERVICES="$LINKED_SERVICES $KEY_VAULT"

      for linked_service in $LINKED_SERVICES; do
        echo "deleting linked service $linked_service..."

        az datafactory linked-service delete \
          --name $linked_service \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
	        --only-show-errors \
	        --yes
      done
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [null_resource.destroy_datasets]
}

resource null_resource deploy_arm_templates {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      az deployment group create \
        --resource-group "${var.resource_group}" \
        --template-file "${local.arm_template}" \
        --parameters ${var.arm_parameters_file} \
          "sasToken=${module.sas_token.sas}" \
            %{ for key in keys(local.arm_parameters) ~}
              "${key}=${local.arm_parameters[key]}" \
            %{ endfor ~}
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [
    null_resource.disable_triggers,
    null_resource.destroy_linked_services,
    module.storage_account,
  ]
}

resource null_resource enable_triggers {
  count = var.triggers_enabled ? 1 : 0

  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      TRIGGERS=$(
        az datafactory trigger list \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --query "[?properties.runtimeState != 'Started'].name" \
          --output tsv \
          --only-show-errors
      )

      for trigger in $TRIGGERS; do
        echo "starting trigger $trigger..."

        az datafactory trigger start \
          --factory-name "${local.data_factory}" \
          --resource-group "${var.resource_group}" \
          --name "$trigger" \
          --only-show-errors

        exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
          echo "retrying starting trigger $trigger..."

          az datafactory trigger start \
            --factory-name "${local.data_factory}" \
            --resource-group "${var.resource_group}" \
            --name "$trigger" \
            --only-show-errors
        fi
      done

      exit 0
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [
    null_resource.deploy_arm_templates,
    module.virtual_machine
  ]
}

resource azurerm_template_deployment output_ir_key {
  count = var.virtual_machine_enabled ? 1 : 0

  name                = "outputIRKey"
  resource_group_name = var.resource_group
  deployment_mode     = "Incremental"

  template_body = file("${path.module}/output-ir-key.json")

  parameters = {
    "dataFactory" = local.data_factory
    "irName"      = local.integration_runtime
  }

  depends_on = [null_resource.deploy_arm_templates]
}

resource null_resource remove_storage_account {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      az storage account delete \
        --name "${module.storage_account.name}" \
        --resource-group "${var.resource_group}" \
        --yes
    EOF
  }

  triggers = {
    always = uuid()
  }

  depends_on = [
    null_resource.deploy_arm_templates,
    module.virtual_machine
  ]
}
