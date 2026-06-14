# Workflow & UiPath Secrets Management Guide

## Overview

This document provides comprehensive guidance on managing workflows and secrets in the ReFramework-ScrapingProject. It covers how workflow files are configured and how UiPath secrets are securely stored in repository settings.

---

## Table of Contents

1. [Workflow Files](#workflow-files)
2. [UiPath Secrets Management](#uipath-secrets-management)
3. [Repository Settings](#repository-settings)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)

---

## Workflow Files

### What Are Workflow Files?

Workflow files in UiPath orchestrate the RPA automation process. They define the sequence of activities that:
- Extract data from input Excel files
- Store data in Orchestrator Queue
- Process sites one by one
- Scrape bulk data (Images, Descriptions, Titles, PDFs, etc.)

### Workflow File Structure

Typical ReFramework workflows follow this structure:

```
Project Root/
├── Main.xaml                 # Entry point workflow
├── Framework/
│   ├── InitAllApplications.xaml
│   ├── GetTransactionData.xaml
│   ├── Process.xaml
│   ├── CloseAllApplications.xaml
│   └── KillAllProcesses.xaml
├── Configuration/
│   ├── Config.xlsx
│   └── Settings.json
├── Data/
│   └── Input/
│       └── input_data.xlsx   # Input Excel file with site URLs
└── Resources/
    └── Screenshots/
```

### Key Workflow Activities

1. **Initialization**: Set up applications and configurations
2. **Queue Fetch**: Retrieve transaction data from Orchestrator Queue
3. **Processing**: Execute scraping logic for each site
4. **Error Handling**: Manage exceptions and retries
5. **Cleanup**: Close applications and generate reports

---

## UiPath Secrets Management

### Why Secure Secrets?

UiPath secrets are sensitive credentials required for:
- Orchestrator API authentication
- Database connections
- Website authentication (usernames, passwords)
- API keys for third-party services
- Cloud service credentials

### How Secrets Are Stored in Repository Settings

#### Step 1: Navigate to Repository Settings

1. Go to your GitHub repository: `https://github.com/ranjitnk/ReFramework-ScrapingProject`
2. Click on **Settings** tab
3. In the left sidebar, select **Secrets and variables** → **Actions**

#### Step 2: Add GitHub Secrets

GitHub Secrets provide encrypted storage for sensitive data:

```
Settings → Secrets and variables → Actions → New repository secret
```

**Example UiPath-Related Secrets to Add:**

| Secret Name | Description | Example |
|------------|-------------|---------|
| `UIPATH_ORCHESTRATOR_URL` | Orchestrator instance URL | `https://cloud.uipath.com` |
| `UIPATH_TENANT_NAME` | UiPath tenant name | `your-tenant-name` |
| `UIPATH_USERNAME` | Orchestrator username | `your-username` |
| `UIPATH_PASSWORD` | Orchestrator password | `your-password` |
| `UIPATH_API_KEY` | API authentication token | `your-api-key` |
| `DATABASE_CONNECTION_STRING` | Database connection | `Server=...;Database=...` |
| `SCRAPING_CREDENTIALS` | Website login credentials | `username:password` |

#### Step 3: Add Environment Variables

For non-sensitive configuration:

```
Settings → Secrets and variables → Actions → Variables
```

**Example Environment Variables:**

| Variable Name | Description | Value |
|--------------|-------------|-------|
| `UIPATH_PROCESS_NAME` | Process name in Orchestrator | `ScrapingProcess` |
| `QUEUE_NAME` | Orchestrator queue name | `ScrapeQueue` |
| `INPUT_FILE_PATH` | Path to input Excel | `Data/Input/sites.xlsx` |
| `OUTPUT_FOLDER` | Output directory | `Data/Output/` |

### How to Reference Secrets in Workflows

#### In GitHub Actions Workflow (`.github/workflows/`):

```yaml
name: Deploy Scraping Automation

on: [push, pull_request]

jobs:
  deploy:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Orchestrator
        env:
          ORCHESTRATOR_URL: ${{ secrets.UIPATH_ORCHESTRATOR_URL }}
          ORCHESTRATOR_USER: ${{ secrets.UIPATH_USERNAME }}
          ORCHESTRATOR_PASSWORD: ${{ secrets.UIPATH_PASSWORD }}
        run: |
          # PowerShell commands to deploy workflow
          Write-Host "Deploying to $($env:ORCHESTRATOR_URL)"
```

#### In UiPath Orchestrator Queues:

Store secrets in Orchestrator Assets and reference them in your workflows:

```
Config["OrchestratorUrl"] = from_asset("OrchestratorUrl")
Config["Username"] = from_asset("OrchestratorUsername")
Config["Password"] = from_asset("OrchestratorPassword")
```

#### In Configuration Files:

Never hardcode secrets. Use placeholders:

```json
{
  "OrchestratorUrl": "${UIPATH_ORCHESTRATOR_URL}",
  "TenantName": "${UIPATH_TENANT_NAME}",
  "ProcessName": "ScrapingProcess",
  "QueueName": "ScrapeQueue"
}
```

---

## Repository Settings

### Access Repository Secrets

**Path:** `Settings` → `Secrets and variables` → `Actions`

### Managing Secrets

#### Create a Secret:
1. Click **New repository secret**
2. Enter **Name** (e.g., `UIPATH_PASSWORD`)
3. Enter **Value** (the actual secret)
4. Click **Add secret**

#### Update a Secret:
1. Find the secret in the list
2. Click the **pencil icon** (Edit)
3. Update the value
4. Click **Update secret**

#### Delete a Secret:
1. Find the secret in the list
2. Click the **trash icon** (Delete)
3. Confirm deletion

#### Scope & Visibility:
- Secrets are **encrypted** and never displayed in plain text
- Secrets are only accessible in **Actions workflows**
- Each secret's **update date** is visible, but the value is hidden

### Branch-Specific Secrets (if available):

Some repositories allow branch-specific secrets:
1. Go to **Secrets and variables** → **Actions**
2. Under "Repository secrets," click on a secret
3. Select deployment branches (if this option is available)

---

## Best Practices

### 1. Secret Naming Convention

```
PREFIX_SERVICE_DESCRIPTION

Examples:
- UIPATH_ORCHESTRATOR_URL
- DATABASE_CONNECTION_STRING
- SMTP_SERVER_PASSWORD
- SCRAPING_API_KEY
```

### 2. Secret Rotation

- Rotate API keys and passwords **every 90 days**
- Update GitHub secrets immediately after rotation
- Document rotation dates in a separate (private) log

### 3. Least Privilege

- Create separate credentials for development, staging, and production
- Use environment-specific secrets:
  ```
  UIPATH_DEV_PASSWORD
  UIPATH_PROD_PASSWORD
  ```

### 4. Audit Trail

- Review **Settings → Security log** periodically
- Monitor when secrets are accessed in workflows
- Archive old logs for compliance

### 5. Code Review

- Never commit secrets to the repository
- Use `.gitignore` to exclude config files:
  ```
  Configuration/*.xml
  Configuration/*.config
  *.password
  .env
  secrets.json
  ```

### 6. Documentation

- Document all required secrets (without values)
- Include instructions for new team members
- Maintain a separate secure document of all secret names

---

## Secure Workflow Example

### Minimal Workflow with Secrets

```yaml
name: Run Scraping Automation

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  scrape:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run UiPath Process
        env:
          ORCHESTRATOR_URL: ${{ secrets.UIPATH_ORCHESTRATOR_URL }}
          TENANT_NAME: ${{ secrets.UIPATH_TENANT_NAME }}
          USERNAME: ${{ secrets.UIPATH_USERNAME }}
          PASSWORD: ${{ secrets.UIPATH_PASSWORD }}
          PROCESS_NAME: ScrapingProcess
        run: |
          # PowerShell script to trigger Orchestrator process
          $body = @{
              startInfo = @{
                  ReleaseKey = $env:PROCESS_NAME
                  RuntimeType = "Unattended"
              }
          } | ConvertTo-Json
          
          $response = Invoke-RestMethod `
            -Uri "$($env:ORCHESTRATOR_URL)/odata/Jobs/UiPath.Server.Configuration.OData.StartJobs" `
            -Method POST `
            -Headers @{
              "Authorization" = "Bearer $(Get-AccessToken)"
              "Content-Type" = "application/json"
            } `
            -Body $body
          
          Write-Host "Job started: $($response.Value)"
```

---

## Troubleshooting

### Issue: "Secret not found" in workflow

**Solution:**
- Verify secret name matches exactly (case-sensitive)
- Ensure secret is in the correct repository
- Check that workflow syntax is correct: `${{ secrets.SECRET_NAME }}`

### Issue: Secrets exposed in logs

**Solution:**
- GitHub automatically masks secrets in logs
- Avoid passing secrets as command-line arguments
- Use environment variables instead
- Review workflow logs in **Actions** tab

### Issue: Can't access secrets in pull requests

**Solution:**
- Secrets are only available to workflows in the **main branch** and **protected branches**
- Pull request workflows from forks cannot access repository secrets
- Use required status checks to prevent merging untrusted PRs

### Issue: Secret appears in debug logs

**Solution:**
- Never use `echo` or `Write-Host` to output secrets
- Use GitHub's masking feature:
  ```powershell
  Write-Output "::add-mask::${{ secrets.UIPATH_PASSWORD }}"
  ```

---

## Security Checklist

- [ ] All sensitive data is stored as GitHub secrets
- [ ] `.gitignore` prevents committing configuration files
- [ ] Workflow logs are reviewed for accidental secret exposure
- [ ] Secrets are rotated every 90 days
- [ ] Only necessary team members have access to **Settings**
- [ ] Branch protection rules require code reviews before merge
- [ ] All workflows use `ubuntu-latest` or `windows-latest` (not custom runners with exposed secrets)
- [ ] Documentation is updated when secrets are added/removed

---

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [UiPath Orchestrator API Documentation](https://docs.uipath.com/orchestrator/latest/api-guide)
- [UiPath Security Best Practices](https://docs.uipath.com/platform/latest/security/security-best-practices)
- [OWASP Secrets Management](https://owasp.org/www-community/Sensitive_Data_Exposure)

---

## Support & Questions

For questions about workflow management or secrets configuration:
1. Check the troubleshooting section above
2. Review GitHub Actions documentation
3. Contact your UiPath administrator
4. Open an issue in this repository

---

**Last Updated:** June 2026  
**Repository:** ranjitnk/ReFramework-ScrapingProject  
**Document Version:** 1.0
