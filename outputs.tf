# ============================================================================
# Outputs for Microsoft Entra ID Resources
# ============================================================================

# -----------------------------------------------------------------------------
# Tenant Information
# -----------------------------------------------------------------------------
output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "default_domain" {
  description = "Default domain for the tenant"
  value       = data.azuread_domains.default.domains[0].domain_name
}

# -----------------------------------------------------------------------------
# Groups
# -----------------------------------------------------------------------------
output "groups" {
  description = "Created security groups"
  value = {
    for k, v in azuread_group.groups : k => {
      id           = v.id
      display_name = v.display_name
      object_id    = v.object_id
    }
  }
}

# -----------------------------------------------------------------------------
# Users
# -----------------------------------------------------------------------------
output "users" {
  description = "Created users (without passwords)"
  value = {
    for k, v in azuread_user.users : k => {
      id                  = v.id
      display_name        = v.display_name
      user_principal_name = v.user_principal_name
      object_id           = v.object_id
    }
  }
}

# Sensitive output for initial passwords (use with caution)
output "user_initial_passwords" {
  description = "Initial passwords for created users (sensitive)"
  value = {
    for k, v in random_password.user_passwords : k => v.result
  }
  sensitive = true
}

# -----------------------------------------------------------------------------
# OIDC Applications
# -----------------------------------------------------------------------------
output "oidc_applications" {
  description = "OIDC application details for service configuration"
  value = {
    for k, v in azuread_application.oidc_apps : k => {
      client_id    = v.client_id
      object_id    = v.object_id
      display_name = v.display_name
    }
  }
}

output "oidc_client_secrets" {
  description = "OIDC client secrets (sensitive)"
  value = {
    for k, v in azuread_application_password.oidc_secrets : k => v.value
  }
  sensitive = true
}

# -----------------------------------------------------------------------------
# OIDC Configuration Reference
# -----------------------------------------------------------------------------
output "oidc_config" {
  description = "OIDC configuration endpoints for all applications"
  value = {
    issuer_url        = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
    authorization_url = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize"
    token_url         = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"
    userinfo_url      = "https://graph.microsoft.com/oidc/userinfo"
    jwks_url          = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/discovery/v2.0/keys"
    logout_url        = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/logout"
    
    # Per-application config
    applications = {
      for k, v in azuread_application.oidc_apps : k => {
        client_id     = v.client_id
        redirect_uris = v.web[0].redirect_uris
      }
    }
  }
}
