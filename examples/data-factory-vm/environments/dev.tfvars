info = {
  domain      = "project"
  subdomain   = "gemini"
  environment = "dev"
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
    virtual_network_name                = "vnetVelConD01"
    virtual_network_subnet_name         = "vnD01sn001"
  }
]

virtual_machine_ip_config = {
  virtual_network = "vnetVelConD01"
  subnet          = "vnD01sn001"
  resource_group  = "spokeVnetRg"
  ip_address      = "10.202.128.13"
}