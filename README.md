# AgentHunt

AgentHunt is a comprehensive collection of purpose-built Security Copilot plugin skills designed to enhance threat hunting, detection, and investigation workflows in Microsoft Sentinel using Microsoft Defender XDR data, Azure Activity logs, and specialized security datasets.

## 🔍 Purpose

AgentHunt empowers security teams to identify, track, and respond to sophisticated threats across multiple attack surfaces by leveraging a curated library of Kusto Query Language (KQL) queries packaged as Sentinel-compatible YAML-based skills. The collection focuses on real-world attack patterns, administrative abuse, and advanced persistent threats.

## 📦 Skill Categories

### 🔐 **Sign-In & Authentication Analysis** (`SignInLogs/`)
Advanced detection capabilities for authentication-based threats:
- Brute force and password spray detection
- Anomalous geographic sign-in patterns  
- MFA fatigue and bypass attempts
- Cross-tenant admin activity monitoring
- Conditional Access policy analysis
- Account compromise indicators

### ☁️ **Azure Infrastructure Monitoring** (`AzureActivity/`)
Comprehensive Azure administrative activity analysis:
- Sentinel rule and connector modifications
- VM Run Command operations from Azure IPs
- Anomalous resource provisioning patterns
- Azure Machine Learning write operations
- Storage key enumeration attempts
- Administrative actions from VPS providers

### 🛡️ **Defender XDR & Email Security** (`DefenderXdr/MDO/`)
Specialized email threat hunting and configuration analysis:
- Admin override abuse in email delivery
- Appspot domain phishing campaigns
- High-value target identification
- Email security policy bypass detection
- Malicious attachment analysis
- URL reputation and threat correlation

### 🧪 **Lab & Training Queries** (`SentinelLabQueries/`)
Specialized detection for advanced threats in controlled environments:
- Solorigate named pipe activity detection
- OAuth application credential manipulation
- Advanced persistent threat (APT) simulation detection

### 🤖 **AI-Powered Automation & Reasoning** (`LogicApp/`)
Azure Logic App template with Security Copilot agent reasoning capabilities:
- **Automated hunting execution** via Security Copilot plugin skills
- **AI-powered analysis** - Security Copilot reasons over findings to determine relevance
- **Intelligent filtering** - Only escalates "interesting" results based on AI assessment
- **Automated reporting** - Generates concise HTML summaries for security teams
- **Smart notifications** - Email alerts only when AI determines findings warrant attention

## 📁 Directory Structure

```
AgentHunt/
├── huntingTemplate.yaml              # Base template for creating new skills
├── SignInLogs/1D/                    # Authentication & sign-in analysis
│   └── SignInLogQueries.yaml         # 25+ sign-in threat hunting skills
├── AzureActivity/1D/                 # Azure administrative activity monitoring  
│   └── AzureActivityQueries.yaml     # 12+ Azure infrastructure hunting skills
├── DefenderXdr/MDO/1D/               # Email security & XDR analysis
│   └── MdoQueries                    # 40+ email and XDR hunting skills
├── SentinelLabQueries/1D/            # Advanced threat lab detection
│   └── SentinelTrainingLabQueries.yaml # APT and training environment skills
├── LogicApp/                         # AI-powered automation
│   └── template.json                 # Logic App with Security Copilot reasoning agent
└── README.md                         # Project documentation
```

## 🚀 Getting Started

### Prerequisites
- Microsoft Sentinel workspace
- Microsoft Defender XDR with appropriate data connectors
- Security Copilot with plugin support (for automation)
- Azure Log Analytics Workspace with relevant data sources

### Deployment Steps

1. **Configure Settings**: Replace placeholder values in any skill YAML files:
   - `<YOUR_TENANT_ID>`
   - `<YOUR_SUBSCRIPTION_ID>` 
   - `<YOUR_RESOURCE_GROUP_NAME>`
   - `<YOUR_WORKSPACE_NAME>`

2. **Import Skills**: Load the desired skill categories into your Security Copilot plugin setup.

3. **Deploy AI-Powered Automation** (Optional): Deploy the Logic App with Security Copilot reasoning:
   ```bash
   az deployment group create \
     --resource-group <your-rg> \
     --template-file LogicApp/template.json \
     --parameters notificationEmail=<your-email>
   ```
   
   **How it works:**
   - Runs hunting skills weekly via Security Copilot
   - AI agent analyzes results and determines if findings are "interesting"
   - Only sends email reports when AI deems results worth investigating
   - Generates intelligent HTML summaries of significant findings

4. **Execute Hunts**: Use natural language queries in Security Copilot:
   > "Show me signs of brute force attacks in the last 24 hours"
   > "Identify anomalous Azure admin activity from external IPs"
   > "Find email campaigns bypassing security controls"

## 📊 Key Hunting Capabilities

### Authentication Threats
- ✅ Brute force and password spray detection
- ✅ Anomalous geographic access patterns
- ✅ MFA fatigue and bypass attempts  
- ✅ Inactive account activation monitoring
- ✅ Cross-tenant administrative access

### Infrastructure Abuse
- ✅ Suspicious Azure resource provisioning
- ✅ Unauthorized administrative operations
- ✅ VM command execution from Azure IPs
- ✅ Storage account enumeration attacks
- ✅ Machine Learning service abuse

### Email Security  
- ✅ Administrative override abuse detection
- ✅ Domain reputation and phishing campaigns
- ✅ High-value target identification
- ✅ Attachment and URL threat correlation
- ✅ Email security policy violations

### Advanced Threats
- ✅ Named pipe activity (Solorigate indicators)
- ✅ OAuth application manipulation
- ✅ Credential harvesting patterns
- ✅ Lateral movement indicators

### AI-Powered Automation
- ✅ Security Copilot agent reasoning over hunting results
- ✅ Intelligent filtering of false positives
- ✅ Automated relevance assessment ("interesting" vs "noise")
- ✅ Smart escalation and notification workflows
- ✅ Contextual HTML report generation

## 🛠️ Customization

Each skill includes configurable parameters for:
- **Time ranges**: Adjust lookback periods for historical analysis
- **Thresholds**: Modify detection sensitivity based on environment
- **Data sources**: Adapt queries for specific log ingestion patterns
- **Alert actions**: Customize entity mapping and response procedures

## 📈 Use Cases

- **SOC Analysts**: Daily threat hunting with AI-filtered results to reduce noise
- **Security Engineers**: Proactive threat detection with intelligent automation  
- **Red Team**: Attack simulation validation and detection testing
- **Compliance Teams**: Administrative activity monitoring and audit trails
- **Threat Researchers**: Advanced persistent threat pattern analysis
- **Security Operations**: Unattended hunting with AI reasoning to surface only relevant findings

## 🔧 Requirements

- **Microsoft Sentinel** with appropriate pricing tier
- **Defender for Office 365** with email telemetry ingestion
- **Azure Activity Logs** enabled and ingested
- **Security Copilot** with plugin support and agent reasoning capabilities
- **Azure Log Analytics Workspace** with sufficient retention
- **KQL knowledge** for query customization and troubleshooting

## 📫 Feedback & Contributions

Contributions, suggestions, or improvements are welcome! Please:
- Open an issue for bug reports or feature requests
- Submit pull requests for new hunting skills or improvements
- Share feedback on detection effectiveness in your environment

## 📝 License

© 2025 Robert Moriarty — Built for real-world defenders, by real-world defenders.

---

**⚠️ Important**: These hunting queries are designed for authorized security operations in your own environment. Always ensure proper authorization and follow your organization's security policies when deploying and executing these skills.
