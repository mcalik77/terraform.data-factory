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