# AgentHunt

AgentHunt is a collection of purpose-built Security Copilot plugin skills designed to enhance hunting, detection, and investigation workflows in Microsoft Sentinel using Microsoft Defender XDR (formerly Microsoft 365 Defender) data.

## 🔍 Purpose

AgentHunt helps security teams identify, track, and respond to malicious email activity across an organization by leveraging a curated library of Kusto Query Language (KQL) queries packaged as Sentinel-compatible YAML-based skills.

## 📦 Structure

Each skill is defined in a modular YAML format with the following fields:
- `Name`: Unique internal identifier.
- `DisplayName`: User-friendly title.
- `Description`: Overview of the detection/hunting scenario.
- `Settings`: Deployment settings including tenant, subscription, workspace, and the KQL `Template`.

## 📁 Directory Layout

AgentHunt/
├── skills/ # All plugin YAML skill definitions
│ ├── AgentHuntTopMaliciousURLDomains.yaml
│ ├── AgentHuntTop10PercentAttackedUsers.yaml
│ ├── AgentHuntZeroDayThreats.yaml
│ └── ...more
├── README.md # Project overview
└── requirements.txt # (Optional) for automation or tooling

sql
Copy
Edit

## 🚀 Getting Started

To deploy a skill:
1. Replace the placeholder values in the `Settings` block:
   - `<YOUR_TENANT_ID>`
   - `<YOUR_SUBSCRIPTION_ID>`
   - `<YOUR_RESOURCE_GROUP_NAME>`
   - `<YOUR_WORKSPACE_NAME>`

2. Import the skill into your Security Copilot plugin setup.

3. Use the skill in natural language within Security Copilot:
   > "Show me the top 10 malicious URL domains from the last 30 days."

## 🧠 Example Skill

```yaml
- Name: AgentHuntZeroDayThreats
  DisplayName: "AgentHunt - Zero Day Threats"
  Description: Reviews the count of zero day threats detected via URL and file detonations in Defender for Office 365 over the past 30 days.
  Settings:
    Target: Sentinel
    TenantId: "<YOUR_TENANT_ID>"
    SubscriptionId: "<YOUR_SUBSCRIPTION_ID>"
    ResourceGroupName: "<YOUR_RESOURCE_GROUP_NAME>"
    WorkspaceName: "<YOUR_WORKSPACE_NAME>"
    Template: |-
      EmailEvents 
      | where Timestamp > ago(30d) 
      | where DetectionMethods has "URL Detonation" or DetectionMethods has "File Detonation" 
      | count
📌 Requirements
Microsoft Sentinel

Defender for Office 365 with email telemetry

Security Copilot with plugin support

Azure Log Analytics Workspace

🛡 Use Cases
Identify top malicious email senders

Track users who clicked phishing URLs

Detect spoofing attempts with failed authentication

Monitor policy-based overrides (admin/user)

Spot targeted users or campaigns

📫 Feedback
Contributions or suggestions? Open an issue or reach out via GitHub.

© 2025 Robert Moriarty — Built for real-world defenders.
