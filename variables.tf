# ============================================================================
# Variables for Microsoft Entra ID Configuration
# ============================================================================
# Cost-efficient setup for testing environments
# Note: Entra ID Free tier includes basic directory features
# ============================================================================

variable "tenant_id" {
  type        = string
  description = "Azure AD Tenant ID"
}

variable "domain_name" {
  type        = string
  description = "Primary domain name for the Entra ID tenant (e.g., yourdomain.onmicrosoft.com)"
}

# -----------------------------------------------------------------------------
# Groups Configuration
# -----------------------------------------------------------------------------
variable "groups" {
  type = map(object({
    display_name     = string
    description      = string
    security_enabled = optional(bool, true)
    mail_enabled     = optional(bool, false)
    types            = optional(list(string), [])
  }))
  description = "Security and Microsoft 365 groups"
  default     = {}
}

# -----------------------------------------------------------------------------
# Users Configuration
# -----------------------------------------------------------------------------
variable "users" {
  type = map(object({
    display_name        = string
    user_principal_name = string
    mail_nickname       = optional(string, null)
    department          = optional(string, null)
    job_title           = optional(string, null)
    usage_location      = optional(string, "NL")
    groups              = optional(list(string), [])
    account_enabled     = optional(bool, true)
  }))
  description = "User accounts to create"
  default     = {}
}

# -----------------------------------------------------------------------------
# Password Policy (for generated passwords)
# -----------------------------------------------------------------------------
variable "password_length" {
  type        = number
  description = "Length of auto-generated passwords for users"
  default     = 16
}

variable "force_password_change" {
  type        = bool
  description = "Force users to change password on first login"
  default     = true
}

# -----------------------------------------------------------------------------
# OIDC Applications (for GitLab, Kubernetes, ArgoCD, etc.)
# -----------------------------------------------------------------------------
variable "oidc_applications" {
  type = map(object({
    display_name     = string
    redirect_uris    = list(string)
    id_token_enabled = optional(bool, false)
  }))
  description = "OIDC application registrations for service integration"
  default     = {}
}
