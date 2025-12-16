# ============================================================================
# Microsoft Entra ID (Azure AD) Resources
# ============================================================================
# Cost-efficient identity management for testing environments
# 
# COST NOTES:
# - Entra ID Free: Basic directory, user/group management (FREE)
# - Entra ID P1: Conditional access, MFA ($6/user/month)
# - Entra ID P2: Identity protection, PIM ($9/user/month)
# 
# This config uses FREE tier features only!
# ============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "azuread_client_config" "current" {}

data "azuread_domains" "default" {
  only_initial = true
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------
resource "azuread_group" "groups" {
  for_each = var.groups

  display_name     = each.value.display_name
  description      = each.value.description
  security_enabled = each.value.security_enabled
  mail_enabled     = each.value.mail_enabled
  types            = each.value.types

  # Prevent accidental deletion
  prevent_duplicate_names = true
}

# -----------------------------------------------------------------------------
# Random Passwords for Users
# -----------------------------------------------------------------------------
resource "random_password" "user_passwords" {
  for_each = var.users

  length           = var.password_length
  special          = true
  override_special = "!@#$%&*()-_=+[]{}|;:,.<>?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# -----------------------------------------------------------------------------
# Users
# -----------------------------------------------------------------------------
resource "azuread_user" "users" {
  for_each = var.users

  display_name        = each.value.display_name
  user_principal_name = each.value.user_principal_name
  mail_nickname       = each.value.mail_nickname != null ? each.value.mail_nickname : lower(replace(each.value.display_name, " ", "."))
  password            = random_password.user_passwords[each.key].result
  department          = each.value.department
  job_title           = each.value.job_title
  usage_location      = each.value.usage_location
  account_enabled     = each.value.account_enabled

  force_password_change = var.force_password_change

  lifecycle {
    ignore_changes = [password]
  }
}

# -----------------------------------------------------------------------------
# Group Memberships
# -----------------------------------------------------------------------------
locals {
  # Flatten user-to-group memberships
  user_group_memberships = flatten([
    for user_key, user in var.users : [
      for group_key in user.groups : {
        key       = "${user_key}-${group_key}"
        user_key  = user_key
        group_key = group_key
      }
    ]
  ])

  user_group_memberships_map = {
    for membership in local.user_group_memberships : membership.key => membership
  }
}

resource "azuread_group_member" "user_memberships" {
  for_each = local.user_group_memberships_map

  group_object_id  = azuread_group.groups[each.value.group_key].object_id
  member_object_id = azuread_user.users[each.value.user_key].object_id
}

# -----------------------------------------------------------------------------
# OIDC Application Registrations
# For GitLab, Kubernetes, ArgoCD, and other services
# -----------------------------------------------------------------------------
resource "azuread_application" "oidc_apps" {
  for_each = var.oidc_applications

  display_name     = each.value.display_name
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]

  # OIDC/OAuth2 configuration
  web {
    redirect_uris = each.value.redirect_uris

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = each.value.id_token_enabled
    }
  }

  # Include groups claim in tokens (important for RBAC)
  group_membership_claims = ["SecurityGroup"]

  # Optional claims for better integration
  optional_claims {
    id_token {
      name                  = "groups"
      essential             = true
      additional_properties = ["emit_as_roles"]
    }
    access_token {
      name                  = "groups"
      essential             = true
      additional_properties = ["emit_as_roles"]
    }
  }

  # API permissions (Microsoft Graph - User.Read)
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  tags = ["OIDC", "Terraform-managed"]
}

# Service Principals for OIDC Applications
resource "azuread_service_principal" "oidc_spns" {
  for_each = var.oidc_applications

  client_id                    = azuread_application.oidc_apps[each.key].client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  tags = ["OIDC", "Terraform-managed"]
}

# Client Secrets for OIDC Applications
resource "azuread_application_password" "oidc_secrets" {
  for_each = var.oidc_applications

  application_id = azuread_application.oidc_apps[each.key].id
  display_name   = "Terraform-managed OIDC secret"
  end_date       = timeadd(timestamp(), "8760h") # 1 year

  lifecycle {
    ignore_changes = [end_date]
  }
}
