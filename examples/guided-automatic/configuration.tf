variable "testing_max_age" {
    type = number
    default = 604800 // 1 week
}
variable "enforce_max_age" {
    type = number
    default = 31557600 // 1 year - maximum allowed
}

variable "tls_reporting_destination" {
    type = string
    default = "tls-rua@mailcheck.service.ncsc.gov.uk" //if empty no TLS RPT record will be created
}

// Edit this file with your list of domains and subdomains.
variable "domains" {
  type = list(object({
    domain = string
    policy = string
    route53Id = string
    delegated = bool
  }))
  default = [
    {
      domain = "example.gov.uk"
      policy = "testing"
      route53Id ="" // If this domain already exists in this account enter the zone ID here
      delegated = false // The first run will create the zone and output the nameservers, once delegated set this to true
    }
  ]
}