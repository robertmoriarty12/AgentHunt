# XDR Lab - AgentHunt Demonstration Environment

## Overview

The XDR Lab is a demonstration and proof-of-concept (PoC) environment within the AgentHunt repository that showcases automated security incident response using Microsoft Defender for Endpoint, Azure Sentinel, and Security Copilot integration. This lab demonstrates how AgentHunt can be used to programmatically run hunting queries via Security Copilot and reason over query results in the context of Defender for Endpoint incidents.

## Architecture
VM with Defender for Endpoint → Azure Sentinel → Logic App → Security Copilot (AgentHunt) → Email Notification


## Prerequisites

Before setting up the XDR Lab, ensure you have:

- **Azure Subscription** with permissions to create and manage resources
- **Microsoft Defender for Endpoint** access with appropriate licensing
- **Azure Sentinel** workspace configured
- **Security Copilot** access for running automated hunting queries
- **Azure Logic Apps** permissions
- **Windows VM** (Windows 10/11 or Windows Server 2019/2022)

## Setup Instructions

### 1. Set Up a Virtual Machine (VM)

1. Create a new Windows VM in Azure
2. Ensure the VM meets the system requirements for Defender for Endpoint
3. Configure network connectivity to allow communication with Azure services
4. Install and onboard the VM to Microsoft Defender for Endpoint

### 2. Enable XDR Logging to Azure Sentinel

1. Navigate to your Azure Sentinel workspace
2. Go to **Data connectors** → **Microsoft Defender for Endpoint**
3. Click **Open connector page**
4. Follow the configuration steps to enable the integration
5. Verify that Defender for Endpoint data is being ingested into Sentinel

### 3. Deploy the PowerShell Script on the VM

1. Log into the VM using Remote Desktop Protocol (RDP)
2. Navigate to the XdrLab directory in the AgentHunt repository
3. Download the PowerShell script (`[ScriptName].ps1`) to the VM
4. **Note**: The script simulates various security events including:
   - Suspicious file downloads and executions
   - Network connections to potentially malicious domains
   - Registry modifications
   - Process creation events
   - File system changes

### 4. Upload the YAML Custom Plugin

1. Access Security Copilot in your environment
2. Navigate to the plugins section
3. Upload the YAML file (`[PluginName].yaml`) from the XdrLab directory
4. This YAML contains custom hunting queries designed to:
   - Analyze process creation events
   - Investigate network connections
   - Examine file system changes
   - Correlate suspicious activities

### 5. Deploy the Incident Logic App

1. In the Azure portal, navigate to **Logic Apps**
2. Create a new Logic App
3. Import the Logic App template from the XdrLab directory (`[LogicAppTemplate].json`)
4. Configure the Logic App to:
   - Trigger on new Defender for Endpoint incidents
   - Invoke Security Copilot AgentHunt skills
   - Process hunting query results
   - Send email notifications with findings

### 6. Configure Automation Rule in Azure Sentinel

1. In Azure Sentinel, go to **Automation**
2. Create a new **Automation rule**
3. Configure the rule with:
   - **Trigger**: When a new incident is created
   - **Conditions**: Filter for Defender for Endpoint incidents
   - **Action**: Run the deployed Logic App
   - **Incident details**: Pass incident context to the Logic App

### 7. Execute the PowerShell Script

1. On the VM, open PowerShell as Administrator
2. Navigate to the directory containing the downloaded script
3. Execute: `.\[ScriptName].ps1`
4. The script will generate a series of security events that will:
   - Trigger Defender for Endpoint alerts
   - Create incidents in Azure Sentinel
   - Activate the automation rule
   - Invoke the Logic App and AgentHunt workflow

### 8. Review the Email Notification

1. Check your configured email address for notifications
2. The Logic App will send an email containing:
   - Incident summary and context
   - Results from hunting queries executed by AgentHunt
   - Security Copilot's reasoning and analysis
   - Recommended next steps and remediation actions

## Expected Events and Analysis

The PowerShell script simulates realistic attack scenarios that will generate:

- **File-based threats**: Downloads and executions of suspicious files
- **Network anomalies**: Connections to suspicious domains and IP addresses
- **System modifications**: Registry changes and file system alterations
- **Process behavior**: Unusual process creation and execution patterns

AgentHunt will analyze these events using the custom hunting queries, providing:

- **Threat correlation**: Linking related security events
- **Risk assessment**: Evaluating the severity and impact
- **Contextual analysis**: Understanding the attack timeline and methodology
- **Actionable recommendations**: Specific remediation steps

![Incident Response Report and Logic App Flow](./c76c6823-5cf9-4f48-851f-5d9827173f96.png)


## Troubleshooting

### Common Issues

1. **VM not appearing in Defender for Endpoint**:
   - Verify the VM is properly onboarded
   - Check network connectivity and firewall rules

2. **No incidents created in Sentinel**:
   - Confirm the data connector is properly configured
   - Verify the PowerShell script executed successfully

3. **Logic App not triggering**:
   - Check the automation rule configuration
   - Verify the Logic App is properly deployed

4. **No email notifications**:
   - Confirm email configuration in the Logic App
   - Check spam/junk folders

## Security Considerations

- This lab is designed for demonstration purposes only
- Ensure proper network isolation in production environments
- Regularly update and patch all components
- Monitor resource usage and costs in Azure

## Contributing

To contribute to the XDR Lab:

1. Fork the AgentHunt repository
2. Create a feature branch for your changes
3. Test your modifications in a lab environment
4. Submit a pull request with detailed descriptions

## Support

For issues or questions related to the XDR Lab:

- Create an issue in the AgentHunt repository
- Review the existing documentation and troubleshooting guides
- Ensure all prerequisites are met before reporting issues

---


**Note**: This lab environment is for educational and demonstration purposes. Always follow your organization's security policies and procedures when implementing similar solutions in production environments.
