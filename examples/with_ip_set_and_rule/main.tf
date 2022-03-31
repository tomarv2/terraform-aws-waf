terraform {
  required_version = ">= 1.0.1"
  required_providers {
    aws = {
      version = "~> 3.74"
    }
  }
}

provider "aws" {
  region = var.region
}

module "common" {
  source = "git::git@github.com:tomarv2/terraform-global.git//common?ref=v0.0.1"
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
      # AND rule
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
              search_string         = "/uri/path"
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
        metric_name                = "allow-custom-ip-set-metric"
        sampled_requests_enabled   = false
      }
    },
    {
     # Byte match rules
      name     = "block-uri-path"
      priority = "2"
      action   = "block"

      byte_match_statement = {
        field_to_match = {
          uri_path = "{}"
        }
        positional_constraint = "STARTS_WITH"
        search_string         = "/uri/path"
        priority              = 100
        type                  = "NONE"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "block-uri-path-metric"
        sampled_requests_enabled   = false
      }
    },
  ]
  teamid = var.teamid
  prjid = var.prjid
}