# =============================================================================
# Azure CDN for Static Website Deployment Script
# Assignment: Azure Blob Storage Static Web Hosting
# =============================================================================

$SUBSCRIPTION_ID   = "<subscription-id>"
$RG_NAME           = "rg-static-website"
$LOCATION          = "westeurope"
$STORAGE_ACC_NAME  = "olamileyestaticsite"
$CDN_PROFILE_NAME  = "cdn-static-site-profile"
$CDN_ENDPOINT_NAME = "olamileyestaticsite-cdn"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Azure CDN for Static Website Deployment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ── Set active subscription ───────────────────────────────────────────────────
az account set --subscription $SUBSCRIPTION_ID

# ── Get Storage Account Web Endpoint ──────────────────────────────────────────
Write-Host "Retrieving primary static web endpoint for storage account '$STORAGE_ACC_NAME'..." -ForegroundColor Yellow
$rawEndpoint = az storage account show -g $RG_NAME -n $STORAGE_ACC_NAME --query "primaryEndpoints.web" -o tsv

if ($null -eq $rawEndpoint -or $rawEndpoint -eq "") {
    Write-Error "Could not retrieve static web endpoint. Ensure static website hosting is enabled on storage account '$STORAGE_ACC_NAME'."
    exit 1
}

# Format endpoint (remove https:// and trailing slash)
$originHost = $rawEndpoint.Replace("https://", "").Replace("/", "")
Write-Host "  [OK] Found static website origin: $originHost" -ForegroundColor Green

# ── 1. Create CDN Profile ─────────────────────────────────────────────────────
Write-Host "[1/2] Creating CDN Profile ($CDN_PROFILE_NAME)..." -ForegroundColor Yellow
az cdn profile create `
    --resource-group $RG_NAME `
    --name $CDN_PROFILE_NAME `
    --sku Standard_Microsoft `
    --location $LOCATION `
    --output none
Write-Host "  [OK] CDN Profile created with Standard Microsoft SKU." -ForegroundColor Green

# ── 2. Create CDN Endpoint ────────────────────────────────────────────────────
Write-Host "[2/2] Creating CDN Endpoint ($CDN_ENDPOINT_NAME)..." -ForegroundColor Yellow
az cdn endpoint create `
    --resource-group $RG_NAME `
    --profile-name $CDN_PROFILE_NAME `
    --name $CDN_ENDPOINT_NAME `
    --origin $originHost `
    --origin-host-header $originHost `
    --output none
Write-Host "  [OK] CDN Endpoint created successfully." -ForegroundColor Green

# ── 3. Output Endpoint URL and Custom Domain Instructions ────────────────────
$cdnUrl = "https://$CDN_ENDPOINT_NAME.azureedge.net"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CDN Deployment Complete!" -ForegroundColor Cyan
Write-Host "  CDN Endpoint URL: $cdnUrl" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "--- CUSTOM DOMAIN MAPPING INSTRUCTIONS ---" -ForegroundColor Yellow
Write-Host "1. Access your DNS provider (e.g. GoDaddy, Namecheap) and create a CNAME record:" -ForegroundColor White
Write-Host "   - Host/Name:  www (or @ / subdomain)" -ForegroundColor White
Write-Host "   - Value:      $CDN_ENDPOINT_NAME.azureedge.net" -ForegroundColor White
Write-Host "   - TTL:        3600 (default)" -ForegroundColor White
Write-Host ""
Write-Host "2. Bind the custom domain to the CDN endpoint using Azure CLI:" -ForegroundColor White
Write-Host "   az cdn custom-domain create `" -ForegroundColor Gray
Write-Host "       --resource-group $RG_NAME `" -ForegroundColor Gray
Write-Host "       --profile-name $CDN_PROFILE_NAME `" -ForegroundColor Gray
Write-Host "       --endpoint-name $CDN_ENDPOINT_NAME `" -ForegroundColor Gray
Write-Host "       --name \"mycustomdomain\" `" -ForegroundColor Gray
Write-Host "       --hostname \"www.yourdomain.com\"" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Enable HTTPS on the custom domain (Azure will provision the SSL certificate for free):" -ForegroundColor White
Write-Host "   az cdn custom-domain enable-https `" -ForegroundColor Gray
Write-Host "       --resource-group $RG_NAME `" -ForegroundColor Gray
Write-Host "       --profile-name $CDN_PROFILE_NAME `" -ForegroundColor Gray
Write-Host "       --endpoint-name $CDN_ENDPOINT_NAME `" -ForegroundColor Gray
Write-Host "       --name \"mycustomdomain\"" -ForegroundColor Gray
Write-Host "------------------------------------------" -ForegroundColor Yellow
Write-Host ""
