variable "rules" {
  description = "Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description'])"
  type        = map(list(any))

  # Protocols (tcp, udp, icmp, all - are allowed keywords) or numbers (from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml):
  # All = -1, IPV4-ICMP = 1, TCP = 6, UDP = 17, IPV6-ICMP = 58
  default = {
    http-80-tcp   = [80, 80, "tcp", "HTTP"]
    https-443-tcp = [443, 443, "tcp", "HTTPS"]
    ssh-tcp       = [22, 22, "tcp", "SSH"]

    # This is a fallback rule to pass to lookup() as default. It does not open anything, because it should never be used.
    _ = ["", "", ""]
  }
}

variable "auto_groups" {
  description = "Map of groups of security group rules to use to generate modules (see update_groups.sh)"
  type        = map(map(list(string)))

  # Valid keys - ingress_rules, egress_rules, ingress_with_self, egress_with_self
  default = {
    http-80 = {
      ingress_rules     = ["http-80-tcp"]
      ingress_with_self = ["all-all"]
      egress_rules      = ["all-all"]
    }

    https-443 = {
      ingress_rules     = ["https-443-tcp"]
      ingress_with_self = ["all-all"]
      egress_rules      = ["all-all"]
    }

    ssh = {
      ingress_rules     = ["ssh-tcp"]
      ingress_with_self = ["all-all"]
      egress_rules      = ["all-all"]
    }
  }
}

