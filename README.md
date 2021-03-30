
# MTA-STS/TLS-RPT AWS Module

This repo contains a module and example code for deploying an [MTS-STS](https://tools.ietf.org/html/rfc8461) and [TLS-RPT](https://tools.ietf.org/html/rfc8460) policy for a domin in AWS using [Terraform](https://www.terraform.io/).

This consists of using:
- an AWS API Gateway with a Custom Domain to host the MTA-STS policy
- a TLS certificate provided by AWS ACM
- AWS Route53 to configure the DNS resource records for MTA-STS and TLS-RPT

If the Route53 domain is not natively hosted in the AWS account, a new Route53 zone is created called mta-sts.<domain>

## Prerequisites
In order to complete this activity you will need:

- a live domain with public DNS records you control
- GitHub on your local machine (desktop or CLI) - https://desktop.github.com/
- Terraform on your local machine (https://www.terraform.io/downloads.html)
- Admin access to the AWS Route 53 where the DNS records are hosted
- AWS CLI on your local machine (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## How to use the code

The code can be used in several ways depending on where your domains are hosted and how much configuration you want to do:

1. Basic - with domains hosted in Route 53
2. Basic - with domains hosted with another DNS Provider
3. Advanced - so you can integrate into your other Terraform configurations


## 1. Basic - with domains hosted in Route 53

Using this method you will need to:
- add AWS credentials
- add domains to a configuration file
- run a Terraform command

This will:
- create the required DNS resource records for MTA-STS and TLS-RPT
- publish an MTA-STS policy hosted in AWS API Gateway
- generate and host a valid TLS certificate for the MTA-STS policy

1. [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) if you don't already have it.
2. Run `AWS configure` to add your AWS credentials and store them in a .aws folder in your home directory.
3. Close [this repository](https://github.com/ukgscc/terraform-aws-mtasts) locally if you have not already done so
4. Edit the configuration.tf file in the terraform-aws-mtasts-master directory. Add your list of domains to the domains variable. To add more than one domain copy the section between the square brackets and repeat for each domain, with a comma between each one.
  ```
[
    {
      domain = "example.gov.uk"
      policy = "testing"
      route53Id ="" // If this domain already exists in this account enter the zone ID here
      mx=[] // If the list is empty the mx records will be queried from DNS
      delegated = true // The first run will create the zone and output the nameservers, once delegated set this to true
    }
]
```
The fields mean:
- domain: your email receiving domain
- policy: `enforce` , `testing` or `none` (start with `testing`)
- route53Id: The Route 53 Hosted zone ID if the domain is already in the current AWS account
- mx: A list of the mail servers to use in the policy. If you leave this empty the current records in your DNS will be used.
- delegated: `true` or `false`. When run with a value of false the new zone is created, when true the configuration is completed requiring validation of ownership to issue the certificate. This is ignored if the Route 53 Hosted zone ID is specified.

5. Run `terraform init` in the root directory of the repository.
6. Run `terraform apply`
   
3) Review the output, there are instructions for creating all of the DNS entries in your existing main DNS zone for each domain

4) Once the NS records are created for each domain to successfully delegate the new mta-sts subdomain, change the value of delegated to true.
   
5) run terraform apply again, it will request certificates and complete the process
   
6) Once you have checked all of your mail servers for TLSv1.2 or better, and valid certificates, and checked that the MX records in your policy are correct, change the policy to enforce in configuration.tf (or tfvars)

## Basic - with domains hosted with another DNS Provider
   
## Advanced - so you can integrate into your other Terraform configurations

This method creates a new subdomain in Route53 for each domain called mta-sts, this will need to be delegated from your existing DNS zone for that domain.
CNAMES are used to point _mta-sts.domain and _smtp._tls.domain to records in this new mta-sts zone, these will also need to be created in your existing DNS.

The end result is the same as the automatic mode but uses more declarative terraform and a single step apply.

1) Create an mta-sts subdomain Route53 zone for each of your domains
2) Create NS records in your main domain zone for the new subdomain
3) Create a CNAME record from _mta-sts.domain to _mta-sts.mta-sts.domain
4) Create a CNAME record from _smtp._tls.domain to _smtp._tls.mta-sts.domain
5) Modify the example code for your domain(s)
6) terraform init/plan/apply


## Manual mode example - main domain DNS zone is hosted in Route53 /examples/domain-in-route53

This option is the simplest and does rely on delegation or CNAMEs, however it does require that the main DNS zone for that domain is already hosted in Route53 and the account used has permission to modify that zone.

1) Find the Route53 zone id for your domain in the AWS dashboard
2) Modify the example code with your domain name and zone id
3) terraform init/plan/apply


## How to use the Module

This module assumes AWS Account with access to Route53, API Gateway, and ACM.

It can be used in two modes, depending on whether the zone_id is defined:

1) If the domain onto which you wish to deploy MTA-STS/TLS-RPT is hosted in Route53 and this account has access:

```terraform
module "mtastspolicy_examplecom" {
  source          = "github.com/ukncsc/terraform-aws-mtasts"
  zone_id         = "Z00AAAAAAA0A0A"            // Optional - If not specified then it will run in mode 2
  domain          = "example.com"
  mx              = ["mail.example.com"]        // Optional - default looks up MX records for the domain in DNS 
  mode            = "testing"                   // Optional - default is testing
  reporting_email = "tlsreporting@example.com"  // Optional - default is no TLS-RPT record
}

output "output" {
  value = module.mtastspolicy_examplecom.output
}
```

2) If the domain onto which you wish to deploy MTA-STS/TLS-RPT is hosted elsewhere and you would like to delegate to new zones in Route53:
   
```terraform
  module "mtastspolicy_examplecom" {
  source          = "github.com/ukncsc/terraform-aws-mtasts"
  domain          = "example.com"
  mx              = ["mail.example.com"]        // Optional - default looks up MX records for the domain in DNS 
  mode            = "testing"                   // Optional - default is testing
  reporting_email = "tlsreporting@example.com"  // Optional - default is no TLS-RPT record
  delegated = false                             // Optional - default is false. Change this to true once the new zones are delegated from your domain
  create_subdomain = true                       // Optional - default is true. Change to false if creating the mta-sts zone manually, allows single step apply.
}

output "output" {
  value = module.mtastspolicy_examplecom.output
}
```
When running in Mode 2, the terraform can either be run in a one or two step process.
For a single step process the mta-sts subdomain needs to be created and delegated beforehand and the create_subdomain variable set to false.
The two step process creates the subdomain. The zone delegation instructions are shown after a terraform apply in the Instructions output variable.
If you change delegated=true before following the instructions and fully delegating the DNS then terraform will fail.

Specifying MX is optional, if they are retrieved from DNS you MUST check your policy to ensure the correct values were populated.

If a negative DNS result is cached due to delays updating the delegated zone then you could try clearing the local dns cache e.g. using ipconfig /flushdns on windows, wait a while, or set dns-delegation-checks to false to disable these checks.
