#!/bin/bash
# auto-shutdown-dev-vms.sh
# Deallocates all running VMs in resource groups tagged Environment=Development
# Designed to run on a schedule at 7pm weekdays via Azure Automation
# Usage: ./auto-shutdown-dev-vms.sh
# Requirements: Azure CLI authenticated, Contributor role on dev resource groups

set -e

echo "================================================"
echo "Auto-shutdown: development VMs"
echo "Started: $(date)"
echo "================================================"

# Check Azure CLI is available
if ! command -v az &>/dev/null; then
  echo "ERROR: Azure CLI not installed" >&2
  exit 1
fi

SUBSCRIPTION=$(az account show --query name --output tsv)
echo "Subscription: $SUBSCRIPTION"
echo ""

# Find all resource groups tagged Environment=Development
RG_LIST=$(az group list \
  --query "[?tags.Environment=='Development'].name" \
  --output tsv)

# Check if any development resource groups exist
if [ -z "$RG_LIST" ]; then
  echo "No resource groups tagged Environment=Development found."
  echo "Nothing to shut down."
  exit 0
fi

echo "Development resource groups found:"
echo "$RG_LIST"
echo ""

TOTAL_STOPPED=0

# Loop through each development resource group
for RG in $RG_LIST; do
  echo "--- Processing: $RG ---"

  # Find all running VMs in this resource group
  VM_LIST=$(az vm list \
    --resource-group $RG \
    --show-details \
    --query "[?powerState=='VM running'].name" \
    --output tsv)

  # If no running VMs in this group skip it
  if [ -z "$VM_LIST" ]; then
    echo "No running VMs found in $RG — skipping."
    continue
  fi

  # Deallocate each running VM
  for VM in $VM_LIST; do
    echo "Deallocating: $VM in $RG"
    az vm deallocate \
      --name $VM \
      --resource-group $RG \
      --no-wait
    TOTAL_STOPPED=$((TOTAL_STOPPED + 1))
  done

done

echo ""
echo "================================================"
echo "Shutdown complete: $(date)"
echo "VMs deallocated: $TOTAL_STOPPED"
echo "================================================"
