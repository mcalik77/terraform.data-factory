variable info {
  type = object({
    domain      = string
    subdomain   = string
    environment = string
    sequence    = string
    vm_infix    = string
  })
}

variable tags {
  type = map(string)
}

variable location {
  type = string
}

variable subnet_whitelist {
  type = list(object({
    virtual_network_resource_group_name = string
    virtual_network_name                = string
    virtual_network_subnet_name         = string
  }))
}

variable virtual_machine_ip_config {
  type = object({
    virtual_network = string
    subnet          = string
    resource_group  = string
    ip_address      = string
  })
}

variable ad_password {
  type = string
}

variable network_share_password {
  type = string
}