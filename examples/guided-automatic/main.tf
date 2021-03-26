provider "aws" {
region = "eu-west-2"
}

module "mtastspolicyhosting" {
  count = length(var.domains)
  source          = "../../mta-sts-module"
  domain          = var.domains[count.index].domain
  mode            = var.domains[count.index].policy
  delegated       = var.domains[count.index].delegated
  reporting_email = var.tls_reporting_destination
  zone_id = var.domains[count.index].route53Id
  max_age = var.domains[count.index].policy == "enforce" ? var.enforce_max_age : var.testing_max_age
}

output "output" {
value = join("\n",module.mtastspolicyhosting.*.output)
}
