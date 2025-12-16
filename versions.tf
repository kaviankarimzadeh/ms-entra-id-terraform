# ============================================================================
# Terraform Version and Provider Requirements
# ============================================================================
# Microsoft Entra ID (Azure AD) provider for identity management
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

