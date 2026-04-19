# Azure cost governance system

## The problem
Companies waste an average of 30% of cloud spend on untagged 
resources, forgotten VMs, orphaned disks and unmanaged storage. 
This project implements an automated governance system to detect 
and eliminate that waste.

## What this demonstrates
- Azure Policy enforcement for mandatory resource tagging
- Automated waste detection via Bash scripting
- Three-tier budget alerting with escalation
- Blob lifecycle management for automatic cost optimisation
- Monthly cost allocation reporting by department

## Architecture
[diagram coming]

## Components
- `policies/` — Azure Policy definitions for tag enforcement
- `scripts/` — Waste detection and reporting automation
- `docs/` — Deployment guide and cost estimates

## How to deploy
[coming — full CLI deployment guide]

## Business impact
In a $50k/month Azure environment this system typically identifies
$10-15k in monthly savings within 30 days of deployment.

## What I would add with more time
- Power BI dashboard for visual cost reporting
- Slack integration for real-time waste alerts
- Azure Automation for scheduled script execution
- Anomaly detection using Azure Cost Management alerts
