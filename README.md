# Microsoft Entra ID (Azure AD) Terraform Configuration

Cost-efficient identity management setup for testing and lab environments with OIDC support for GitLab, Kubernetes, ArgoCD, and more.

## 💰 Cost Considerations

**This configuration uses FREE tier features only!**

| Tier | Features | Cost |
|------|----------|------|
| **Entra ID Free** ✅ | Basic directory, users, groups, app registrations, OIDC | **FREE** |
| Entra ID P1 | Conditional access, MFA, dynamic groups | $6/user/month |
| Entra ID P2 | Identity protection, PIM, access reviews | $9/user/month |

## 📋 Prerequisites

1. **Azure Account**: Free tier is sufficient
2. **Azure CLI**: Install from [Microsoft Docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Terraform**: Version >= 1.5.0

## 🚀 Quick Start

### 1. Authenticate with Azure

```bash
az login
az account show --query tenantId -o tsv
```

### 2. Configure Terraform

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your tenant_id and domain_name
```

### 3. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 4. Get User Passwords

```bash
# Get all user passwords (sensitive)
terraform output -json user_initial_passwords
```

> **Note**: Users are forced to change their password on first login (`force_password_change = true`).

### 5. Get OIDC Configuration

```bash
# Get all OIDC endpoints
terraform output oidc_config

# Get client IDs
terraform output -json oidc_applications

# Get client secrets (sensitive)
terraform output -json oidc_client_secrets
```

## 📁 Created Resources

| Resource | Description |
|----------|-------------|
| **Security Groups** | For RBAC (dev-team, ops-team, qa-team, etc.) |
| **Users** | Test users with auto-generated passwords |
| **OIDC Applications** | App registrations for GitLab, ArgoCD, K8s, etc. |

## 🔗 OIDC Integration Examples

### GitLab Configuration

```ruby
# /etc/gitlab/gitlab.rb
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Azure AD",
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer: "https://login.microsoftonline.com/TENANT_ID/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "CLIENT_ID",      # from: terraform output -json oidc_applications
        secret: "CLIENT_SECRET",      # from: terraform output -json oidc_client_secrets
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

### ArgoCD Configuration

```yaml
# argocd-cm ConfigMap
data:
  url: https://argocd.example.com
  oidc.config: |
    name: Azure AD
    issuer: https://login.microsoftonline.com/TENANT_ID/v2.0
    clientID: CLIENT_ID
    clientSecret: $oidc.azure.clientSecret
    requestedScopes:
      - openid
      - profile
      - email

# argocd-rbac-cm ConfigMap (map Entra groups to ArgoCD roles)
data:
  policy.csv: |
    g, GROUP_OBJECT_ID, role:admin
  scopes: '[groups, email]'
```

```yaml
# argocd-secret (add client secret)
stringData:
  oidc.azure.clientSecret: CLIENT_SECRET
```

### Kubernetes API Server (OIDC)

```yaml
# kube-apiserver flags
--oidc-issuer-url=https://login.microsoftonline.com/TENANT_ID/v2.0
--oidc-client-id=CLIENT_ID
--oidc-username-claim=preferred_username
--oidc-groups-claim=groups
```

### kubectl with OIDC (kubelogin)

```bash
# Install kubelogin
brew install int128/kubelogin/kubelogin

# Configure kubeconfig
kubectl config set-credentials oidc-user \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://login.microsoftonline.com/TENANT_ID/v2.0 \
  --exec-arg=--oidc-client-id=CLIENT_ID \
  --exec-arg=--oidc-client-secret=CLIENT_SECRET
```


## 📊 Outputs Reference

| Output | Description |
|--------|-------------|
| `tenant_id` | Azure AD Tenant ID |
| `default_domain` | Primary domain name |
| `groups` | Security groups with object IDs |
| `users` | Users (without passwords) |
| `user_initial_passwords` | Initial passwords (sensitive) |
| `oidc_applications` | App registrations with client IDs |
| `oidc_client_secrets` | Client secrets (sensitive) |
| `oidc_config` | All OIDC endpoints |

## 📝 Add New OIDC Application

```hcl
# terraform.tfvars
oidc_applications = {
  "my-new-app" = {
    display_name     = "My New Application"
    redirect_uris    = ["https://myapp.example.com/callback"]
    id_token_enabled = false  # Set true for kubectl/kubelogin
  }
}
```

## 🔒 Security Notes

1. **Group Claims**: Tokens include group memberships for RBAC
2. **Secrets Rotation**: App secrets expire after 1 year
3. **Password Policy**: Users forced to change password on first login

## 🧹 Cleanup

```bash
terraform destroy
```

## 🆘 Troubleshooting

### AADSTS50011: Reply URL mismatch

Ensure redirect_uris in terraform.tfvars exactly match your application's callback URL.

### Groups not appearing in token

1. Check group membership claims are configured (done automatically)
2. Verify user is member of the group
3. For large number of groups, Azure returns a link instead - configure group filtering

### Permission Denied

Your Azure account needs:
- **User Administrator** role for creating users
- **Application Administrator** role for app registrations
