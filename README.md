<p align="center">
    <a href="https://github.com/tomarv2/terraform-aws-waf/actions/workflows/pre-commit.yml" alt="Precommit">
        <img src="https://github.com/tomarv2/terraform-aws-waf/actions/workflows/pre-commit.yml/badge.svg?branch=main" /></a>
    <a href="https://www.apache.org/licenses/LICENSE-2.0" alt="license">
        <img src="https://img.shields.io/github/license/tomarv2/terraform-aws-waf" /></a>
    <a href="https://github.com/tomarv2/terraform-aws-waf/tags" alt="GitHub tag">
        <img src="https://img.shields.io/github/v/tag/tomarv2/terraform-aws-waf" /></a>
    <a href="https://github.com/tomarv2/terraform-aws-waf/pulse" alt="Activity">
        <img src="https://img.shields.io/github/commit-activity/m/tomarv2/terraform-aws-waf" /></a>
    <a href="https://stackoverflow.com/users/6679867/tomarv2" alt="Stack Exchange reputation">
        <img src="https://img.shields.io/stackexchange/stackoverflow/r/6679867"></a>
    <a href="https://twitter.com/intent/follow?screen_name=tomar_v2" alt="follow on Twitter">
        <img src="https://img.shields.io/twitter/follow/tomar_v2?style=social&logo=twitter"></a>
</p>

## Terraform module for [Amazon WAFv2](https://docs.aws.amazon.com/waf/latest/APIReference/Welcome.html)

### Versions

- Module tested for Terraform 1.0.1.
- AWS provider version [4.35](https://registry.terraform.io/providers/hashicorp/aws/latest).
- `main` branch: Provider versions not pinned to keep up with Terraform releases.
- `tags` releases: Tags are pinned with versions (use <a href="https://github.com/tomarv2/terraform-aws-waf/tags" alt="GitHub tag">
  <img src="https://img.shields.io/github/v/tag/tomarv2/terraform-aws-waf" /></a> in your releases).

### Usage

#### Option 1:

```
terrafrom init
terraform plan -var='teamid=tryme' -var='prjid=project1'
terraform apply -var='teamid=tryme' -var='prjid=project1'
terraform destroy -var='teamid=tryme' -var='prjid=project1'
```

**Note:** With this option please take care of remote state storage

#### Option 2:

##### Recommended method (stores remote state in remote backend(S3, Azure storage, or Google bucket) using `prjid` and `teamid` to create directory structure):

- Create python 3.8+ virtual environment

```
python3 -m venv <venv name>
```

- Install package:

```
pip install tfremote --upgrade
```

- Set below environment variables:

```
export TF_AWS_BUCKET=<remote state bucket name>
export TF_AWS_BUCKET_REGION=us-west-2
export TF_AWS_PROFILE=<profile from ~/.ws/credentials>
```

or

- Set below environment variables:

```
export TF_AWS_BUCKET=<remote state bucket name>
export TF_AWS_BUCKET_REGION=us-west-2
export AWS_ACCESS_KEY_ID=<aws_access_key_id>
export AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
```

- Updated `examples` directory with required values.

- Run and verify the output before deploying:

```
tf -c=aws plan -var='teamid=foo' -var='prjid=bar'
```

- Run below to deploy:

```
tf -c=aws apply -var='teamid=foo' -var='prjid=bar'
```

- Run below to destroy:

```
tf -c=aws destroy -var='teamid=foo' -var='prjid=bar'
```

**Note:** Read more on [tfremote](https://github.com/tomarv2/tfremote)

##### WAF with custom IP and `AND` rule

```
terraform {
  required_version = ">= 1.0.1"
  required_providers {
    aws = {
      version = "~> 4.61"
    }
  }
}

provider "aws" {
  region = var.region
}

module "common" {
  source = "github.com/tomarv2/terraform-global.git//common?ref=v0.0.1"
}

#####
# IP set resources
#####
resource "aws_wafv2_ip_set" "custom_ip_set" {
  name = "${var.name_prefix}-custom-ip-set"

  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = module.common.cidr_for_sec_grp_access
}

module "waf" {
  source = "../.."

  allow_default_action = false
  scope = "REGIONAL"
  alb_arn = "arn:aws:elasticloadbalancing:us-west-2:12345789012:loadbalancer/app/demo-app/abcdef"
  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.name_prefix}-waf-setup-waf-main-metrics"
    sampled_requests_enabled   = false
  }

  rules = [
    # Custom ip addresses
    {
      name     = "allow-custom-ip-set"
      priority = 1
      action   = "allow"
      ip_set_reference_statement = {
        arn = aws_wafv2_ip_set.custom_ip_set.arn
      }
      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "allow-custom-ip-set-metric"
        sampled_requests_enabled   = false
      }
    },
    {
      ### AND rule
      name     = "allow-specific-uri-path-from-webhook"
      priority = 5
      action   = "allow"
      and_statement = {
        statements = [ # 2 or more statements are required for AND
          {
            byte_match_statement = {
              field_to_match = {
                uri_path = "{}"
              }
              positional_constraint = "STARTS_WITH"
              search_string         = "/webhook"
              priority              = 0
              type                  = "NONE"
            }
          },
          {
            byte_match_statement = {
              field_to_match = {
                single_header = {"name": "x-demo"}
              }
              positional_constraint = "EXACTLY"
              search_string         = "hello_world"
              priority              = 0
              type                  = "NONE"
            }
          }
        ]
      }
      visibility_config = {
        cloudwatch_metrics_enabled = false
        sampled_requests_enabled   = false
      }
    }
  ]
  teamid = var.teamid
  prjid = var.prjid
}
```

Please refer to examples directory [link](examples) for references.

<!-- BEGIN_TF_DOCS -->

## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.

<!-- END_TF_DOCS -->
