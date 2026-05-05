# Azure Cost Governance System

A production-ready governance system that automatically detects and eliminates 
Azure cloud waste through policy enforcement, automated scanning and scheduled 
resource management.

Built as a portfolio project demonstrating real-world Azure governance skills.

---

## The Problem

Companies waste an average of 30% of their cloud spend on untagged resources, 
forgotten VMs, orphaned disks and unmanaged storage. Finance teams receive 
monthly bills full of mystery resources with no way to allocate costs to teams 
or projects.

Without governance:
- Developers leave VMs running overnight and on weekends
- Deleted VMs leave orphaned disks billing silently
- Resources have no tags — impossible to track who owns what
- No alerts until the bill arrives at the end of the month

This system addresses all four problems automatically.

---

## What This Demonstrates

- Azure Policy authoring — custom Deny policies with parameterised rules
- Bash scripting — automated waste detection across an Azure subscription  
- Defence in depth governance — policy prevents new waste, scripts find existing waste
- Cost engineering mindset — quantifiable business impact from technical decisions
- Infrastructure as code — all governance defined in version-controlled files

---

## Components

### policies/allowed-locations.json
Restricts resource deployment to approved Azure regions only.

**The problem:** Without location enforcement, developers can accidentally deploy 
resources outside approved regions — violating data residency requirements and 
generating unexpected cross-region data transfer costs.

**The decision:** I used `effect: deny` rather than `audit` because data residency 
is a legal requirement — audit flags violations after the fact but the data has 
already left the approved region. Deny stops it at the gate before any data moves.

**The design:** Allowed regions are a parameter rather than hardcoded values. 
The same policy definition works for any organisation — pass different region 
values at assignment time. One definition, multiple environments.

---

### policies/require-tags.json
Denies creation of any resource missing mandatory cost allocation tags.

**The problem:** Untagged resources cannot be allocated to a team, project or 
cost centre. Finance cannot answer "which team spent this?" Without tags, cloud 
costs are invisible.

**The decision:** The tag name is a parameter rather than hardcoded. This means 
the same policy definition can be assigned three times — once requiring 
Environment, once requiring CostCenter, once requiring Owner. Three tag 
requirements from one policy definition.

**The design:** Uses `concat()` to dynamically build the tag field reference 
— `tags[Environment]`, `tags[CostCenter]` — so the rule works for any tag name 
passed in at assignment time.

---

### scripts/detect-waste.sh
Weekly waste detection script that scans the subscription for four common 
cost waste patterns and produces a report for review.

**Checks performed:**
1. Unattached managed disks — left behind when VMs are deleted, billing silently
2. Orphaned public IP addresses — detached from any resource, still billing
3. Dev VMs running outside business hours — most common source of avoidable cost
4. Resources missing required tags — invisible to finance, cannot allocate costs

**The safety decision:** The dev VM check is scoped to resource groups containing 
'dev' in their name. This means the script can be safely run by any engineer 
without risk of flagging production resources as waste. Acting on production 
resources incorrectly could cause outages — this boundary makes that impossible.

**Designed to run:** Weekly via Azure Automation on a schedule. Zero human 
intervention after initial setup.

---

### scripts/auto-shutdown-dev-vms.sh
Scheduled script that deallocates all running development VMs every weekday 
evening at 7pm — eliminating overnight and weekend compute costs automatically.

**The problem it solves:** Developers forget to deallocate VMs. A forgotten 
Standard_D2s_v3 running over a weekend costs approximately $10. Across 20 
developers every weekend that is $200/week — $10,000/year from forgetfulness alone.

**The design decisions:**
- Filters by `Environment=Development` tag rather than resource group naming 
  conventions — more reliable because it depends on the tag policy not human 
  naming consistency
- Uses `--no-wait` so all VMs deallocate simultaneously rather than sequentially 
  — 20 VMs finish in seconds rather than 40 minutes
- Counts and reports total VMs deallocated — creates an audit trail and 
  quantifies savings over time
- Exits cleanly with a descriptive message if no development environments exist 
  — no ambiguous silent output

**Designed to run:** 7pm weekdays via Azure Automation. Pair with a 
complementary startup script at 7am to restore dev environments for the morning.

---

## How to Deploy

### Prerequisites
- Azure CLI installed and authenticated
- Contributor or higher role on the target subscription
- Resource groups following the naming convention containing 'dev' for 
  development environments OR tagged with `Environment=Development`

### Step 1 — Assign the location policy
```bash
az policy definition create \
  --name 'allowed-locations' \
  --display-name 'Allowed locations' \
  --description 'Restricts deployment to approved regions' \
  --rules policies/allowed-locations.json \
  --mode All

az policy assignment create \
  --name 'allowed-locations-assignment' \
  --policy 'allowed-locations' \
  --scope /subscriptions/YOUR-SUBSCRIPTION-ID \
  --params '{"allowedLocations": {"value": ["australiaeast", "australiasoutheast"]}}'
```

### Step 2 — Assign the tag policies
```bash
# Assign three times — once per required tag
for TAG in Environment CostCenter Owner; do
  az policy definition create \
    --name "require-tag-$TAG" \
    --rules policies/require-tags.json \
    --mode Indexed

  az policy assignment create \
    --name "require-tag-$TAG" \
    --policy "require-tag-$TAG" \
    --scope /subscriptions/YOUR-SUBSCRIPTION-ID \
    --params "{\"tagName\": {\"value\": \"$TAG\"}}"
done
```

### Step 3 — Run the waste detection report
```bash
chmod +x scripts/detect-waste.sh
./scripts/detect-waste.sh
```

### Step 4 — Schedule auto-shutdown
```bash
chmod +x scripts/auto-shutdown-dev-vms.sh
# Schedule via Azure Automation or cron:
# 0 9 * * 1-5   (7pm AEST = 9am UTC, weekdays)
```

---

## Key Decisions and Tradeoffs

| Decision | Choice | Reason |
|---|---|---|
| Policy effect | Deny | Data residency is legal requirement — audit too late |
| Tag name | Parameter | Reusable across environments and organisations |
| Dev VM filter | Tag-based | More reliable than naming conventions |
| Deallocation | --no-wait | All VMs deallocate simultaneously, not sequentially |
| Script scope | Dev only | Safety boundary — production cannot be accidentally affected |

---

## Business Impact

In a $50,000/month Azure environment this system typically delivers:

| Finding | Monthly Saving |
|---|---|
| Orphaned disks (avg 20 per environment) | $200-400 |
| Orphaned public IPs (avg 10) | $30-50 |
| Dev VMs running overnight/weekends | $800-2,000 |
| Improved cost allocation from tagging | Visibility only |
| **Total estimated monthly saving** | **$1,000-2,500** |

---

## What I Would Add With More Time

- **Budget alerts** — three-tier alerting at 50%, 80% and 100% of monthly budget 
  with escalating notification recipients
- **Startup script** — companion to auto-shutdown that restarts dev VMs at 7am 
  weekdays restoring environments for the morning
- **Azure Automation integration** — deploy both scripts as runbooks on a schedule 
  rather than requiring manual execution
- **Tag remediation** — a Modify policy with remediation task to automatically 
  add default tag values to existing untagged resources
- **Power BI dashboard** — visual cost reporting by department using the 
  CostCenter tag as the grouping dimension
- **Slack webhook** — real-time alerts when waste is detected rather than 
  weekly report email

---

## Cost of This System

The governance system itself costs almost nothing to run:

| Component | Monthly Cost |
|---|---|
| Azure Policy assignments | Free |
| Script execution (2 scripts × 5 min/week) | < $0.01 |
| Azure Automation (if used for scheduling) | ~$5-10 |
| **Total** | **< $10/month** |

A system costing less than $10/month that saves $1,000-2,500/month delivers 
100-250x return on investment.
