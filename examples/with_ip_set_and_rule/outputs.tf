output "web_acl_name" {
  description = "The name of the WAFv2 WebACL."
  value       = module.waf.web_acl_name
}

output "web_acl_arn" {
  description = "The ARN of the WAFv2 WebACL."
  value       = module.waf.web_acl_arn
}

output "web_acl_rule_names" {
  description = "List of created rule names"
  value       = module.waf.web_acl_rule_names
}

output "allowed_ip_set_arn" {
  description = "The ARN of the allowed IP list"
  value       = aws_wafv2_ip_set.custom_ip_set.arn
}

output "allowed_ip_list" {
  description = "The list of the aloowed IPs"
  value       = aws_wafv2_ip_set.custom_ip_set.addresses
}
