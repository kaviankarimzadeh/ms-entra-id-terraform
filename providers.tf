# ============================================================================
# Provider Configuration
# ============================================================================
# Azure AD (Entra ID) provider configuration
# Authentication can be done via:
#   - Azure CLI: az login
#   - Service Principal: set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
#   - Managed Identity: when running in Azure
# ============================================================================

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "random" {}

