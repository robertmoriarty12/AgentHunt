# AgentHunt Incident Response Logic App — Deployment Guide

This guide explains how to deploy a **Logic App (Consumption)** that orchestrates an incident-response workflow using **Microsoft Sentinel incidents**, **Security Copilot**, and **Office 365 Outlook**. The template is environment‑agnostic—no hard‑coded IDs—and only requires you to **authorize the API connections after deployment**.

> ✅ Your JSON template is “plug-and-play.” After deployment, open each API connection and **Authorize** (then **Save**) as shown in the screenshot below.

![Authorize API connections](./9e09f3c8-f3af-41ea-9f31-6ea67ae6ea32.png)

---

## What you get

- **Trigger:** Microsoft Sentinel incident creation (`ApiConnectionWebhook` trigger)
- **Actions (example):** Call Security Copilot skills to summarize the incident and run hunting steps, then build an HTML incident report
- **Notification:** Email the report via Office 365 Outlook (Send an email (V2))

> Exact action names may differ slightly in your template, but the post‑deploy steps are the same.

---

## Prerequisites

- Azure subscription + permission to deploy to a resource group
- Access to:
  - **Microsoft Sentinel** (to read incidents in the target workspace)
  - **Security Copilot**
  - **Office 365 Outlook** (mailbox with permission to send)
- A region that supports the connectors (most public regions do). If you hit a regional availability error for a managed API, redeploy in another region.

---

## Files

- **Logic App ARM template:** `<your-working-incident-response>.json`
- (Optional) `parameters.json` for repeatable deployments

> Tip: Keep the ARM file and this README in the same folder so the screenshot reference works. If you place the README elsewhere, adjust the image path accordingly.

---

## Deploy (Azure Portal)

1. Go to **Resource groups** → **Create** (or pick an existing RG).
2. In the RG, click **Deploy a custom template** → **Build your own template in the editor** → **Load file** → select your JSON file → **Save**.
3. Fill the parameters:
   - **workflowName** (e.g., `secCopilotHunting-Incident-Playbook`)
   - **location** (e.g., the RG’s region)
   - Any others your template exposes (e.g., `notificationRecipients`)
4. Click **Review + create** → **Create**.

When deployment completes, open the Logic App resource.

---

## Deploy (Azure CLI)

```bash
# 1) Create (or reuse) a resource group
az group create -n agenthunt-rg -l centralus

# 2) Deploy the template
az deployment group create \
  -g agenthunt-rg \
  -n agenthunt-incident-deploy \
  --template-file <your-working-incident-response>.json \
  --parameters workflowName="secCopilotHunting-Incident-Playbook" \
               notificationRecipients="soc-team@contoso.com"
```

> If your template has different parameter names, adjust accordingly.

---

## Post‑Deploy (Important): Authorize API connections

Open the Logic App → **API connections** and **Authorize** each connection, then **Save**:

1. **Microsoft Sentinel** connection (e.g., `azuresentinel-<workflowName>`)
   - Click **Authorize**, sign in with an account that has read access to the Sentinel workspace where incidents are created.
2. **Security Copilot** connection (e.g., `securitycopilot-1`)
   - Click **Authorize** and sign in. This account should be licensed/permissioned for Security Copilot.
3. **Office 365 Outlook** connection (e.g., `office365-1`)
   - Click **Authorize** with the mailbox that will send the incident email. Ensure the account can send messages to your recipient list.

> The screenshot above shows the **Authorize** button in the **Edit API connection** blade. Use it for each of the three connections and then click **Save**.

---

## RBAC considerations

- The identity you **authorize** for the **Sentinel** connection must be able to read incidents in the target workspace.
- The **Office 365** connection sends mail **as the authorized user**. If you need to send from a shared mailbox or distribution list, confirm send‑as or send‑on‑behalf permissions.
- If your template assigns a **System‑assigned managed identity** to the Logic App for other operations, grant it the necessary roles on target resources (e.g., Log Analytics Reader, Microsoft Sentinel Responder).

---

## Test the workflow

- **Natural path:** Create (or simulate) an incident in the connected Sentinel workspace and wait for the Logic App to trigger.
- **Manual test:** Open **Logic app designer** → pick the most recent run → **Resubmit** (if available) or design a manual test path if your template includes an HTTP Request trigger variant.
- **Email result:** Confirm the SOC email arrives with an HTML incident summary. If not, see Troubleshooting.

---

## Troubleshooting

**`ApiConnectionNotFound`**  
- The workflow tried to use a connection that isn’t created, or the name mismatched. Re‑open **API connections**, confirm the three connections exist and are **Authorized**, then **Save**. Re‑run.

**`The 'id' property ... managedApis/... is not valid`**  
- The connection’s `properties.api.id` must point to the *subscription‑scope* managed API:  
  `/subscriptions/{subId}/providers/Microsoft.Web/locations/{location}/managedApis/{connector}`  
  Redeploy with a template that builds this using `subscriptionResourceId('Microsoft.Web/locations/managedApis', <location>, '<connector>')`.

**`parameterValueType` / `nonSecretParameterValues` errors**  
- Remove these legacy fields; most connectors only need `properties.api.id` and an empty `parameterValues` at deploy time. Do the **Authorize** step post‑deploy.

**401 / permissions**  
- The authorized user for Sentinel must have read permissions in the target workspace.
- The Office 365 user must be allowed to send mail to the recipients (and send‑as the mailbox if applicable).

**No emails delivered**  
- Verify the **Office 365** connection is **Authorized** and **Saved**.  
- Check the **Send email (V2)** action: recipient list and body mapping.  
- Review **Run history** for any action errors.

---

## Customization tips

- **Recipients:** Parameterize a default (e.g., `notificationRecipients`) and also allow per‑run overrides if you add an HTTP Request trigger.
- **Branding:** Your `/askgpt` step can prepend a header, logo, or CSS for a more polished HTML email.
- **Skill sequence:** Reorder or add Security Copilot prompts to run additional hunts before the report step.

---

## FAQ

**Q: Do I need to hard‑code tenant, subscription, or workspace IDs?**  
**A:** No. The connections are tenant‑agnostic at deploy time. You bind them by clicking **Authorize** post‑deploy.

**Q: Can I use a different region than the resource group?**  
**A:** Yes, but ensure the region supports the managed APIs. If you hit a “managedApis not found” error, try a nearby region.

**Q: Can I use Managed Identity for Sentinel instead of a user connection?**  
**A:** Yes, but the workflow and connection schema differ. Start with the working user‑authorized pattern, then iterate to MSI if you want to avoid user‑bound tokens.
