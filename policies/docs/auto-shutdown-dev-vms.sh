cat > scripts/auto-shutdown-dev-vms.sh << 'EOF'
#!/bin/bash
# auto-shutdown-dev-vms.sh
# Deallocates all VMs in resource groups tagged Environment=Development
# Schedule via cron: 0 19 * * 1-5 (7pm weekdays)

RG_LIST=$(az group list \
  --query "[?tags.Environment=='Development'].name" \
  --output tsv)

for RG in $RG_LIST; do
  echo "Processing resource group: $RG"
  VM_LIST=$(az vm list \
    --resource-group $RG \
    --show-details \
    --query "[?powerState=='VM running'].name" \
    --output tsv)
  for VM in $VM_LIST; do
    echo "Deallocating: $VM in $RG"
    az vm deallocate \
      --name $VM \
      --resource-group $RG \
      --no-wait
  done
done

echo "Auto-shutdown complete: $(date)"
EOF

chmod +x scripts/auto-shutdown-dev-vms.sh
git add .
git commit -m "add auto-shutdown script for dev VMs — runs at 7pm weekdays"
git push
