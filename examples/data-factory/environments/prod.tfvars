info = {
  domain      = "project"
  subdomain   = "gemini"
  environment = "prod"
  sequence    = "001"
  vm_infix    = "pg"
}

tags = {
  project = "Gemini"
  owner   = "Massimo Cannavo"
}

location = "South Central US"

subnet_whitelist = [
  {
    virtual_network_resource_group_name = "spokeVnetRg"
    virtual_network_name                = "vnetVelConP01"
    virtual_network_subnet_name         = "vnP01sn001"
  }
]