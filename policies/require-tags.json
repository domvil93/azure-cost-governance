cat > scripts/detect-waste.sh << 'EOF'
#!/bin/bash
# detect-waste.sh
# Scans Azure subscription for common cost waste patterns
# Usage: ./detect-waste.sh
# Requirements: Azure CLI authenticated, Contributor or Reader role

set -e

echo "================================================"
echo "Azure cost waste detection report"
echo "Generated: $(date)"
echo "================================================"

# Check Azure CLI is available
if ! command -v az &>/dev/null; then
  echo "ERROR: Azure CLI not installed" >&2
  exit 1
fi

SUBSCRIPTION=$(az account show --query name --output tsv)
echo "Subscription: $SUBSCRIPTION"
echo ""

echo "--- Unattached managed disks ---"
echo "These disks are not attached to any VM and are billing unnecessarily."
az disk list \
  --query "[?diskState=='Unattached'].{Name:name, Size:diskSizeGb, RG:resourceGroup, SKU:sku.name}" \
  --output table

echo ""
echo "--- Unassociated public IP addresses ---"
echo "Public IPs not associated with any resource — billing with no purpose."
az network public-ip list \
  --query "[?ipConfiguration==null].{Name:name, RG:resourceGroup, SKU:sku.name}" \
  --output table

echo ""
echo "--- VMs running in development resource groups ---"
echo "Dev VMs that should be deallocated outside business hours."
az vm list \
  --show-details \
  --query "[?contains(resourceGroup, 'dev') && powerState=='VM running'].{Name:name, RG:resourceGroup, Size:hardwareProfile.vmSize, State:powerState}" \
  --output table

echo ""
echo "--- Resources missing required tags ---"
echo "Untagged resources that cannot be allocated to a cost centre."
az resource list \
  --query "[?tags.Environment==null || tags.CostCenter==null].{Name:name, Type:type, RG:resourceGroup}" \
  --output table

echo ""
echo "================================================"
echo "Report complete. Review flagged resources above."
echo "================================================"
EOF

chmod +x scripts/detect-waste.sh

git add .
git commit -m "add waste detection script — unattached disks, orphaned IPs, untagged resources"
git push
