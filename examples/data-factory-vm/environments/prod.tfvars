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
    virtual_network_subnet_name         = "vnP01sn003"
  }
]

virtual_machine_ip_config = {
  virtual_network = "vnetVelConP01"
  subnet          = "vnP01sn003"
  resource_group  = "spokeVnetRg"
  ip_address      = "10.200.128.77"
}