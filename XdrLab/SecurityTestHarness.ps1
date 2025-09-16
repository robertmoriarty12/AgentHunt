<#
.SYNOPSIS
  LabHarness.ps1 — lab telemetry generator for AgentHunt demos.
.DESCRIPTION
  Generates broad, generic telemetry across process, network, file, registry, and scheduled-task surfaces
  so hunting queries (AgentHunt) have interesting data to reason about.

  ALL features are enabled by default. Toggle via the switches when calling the script.

  RUN ONLY IN AN ISOLATED LAB VM WITH ADMIN RIGHTS.

  THIS IS FOR A LAB ENVIRONMENT
#>

param(
    # Basic logging
    [string]$LogPath = "C:\Temp\LabHarness\SecurityTest.log",

    # EICAR
    [string]$EicarFolder = "C:\Temp\EICARTest",
    [string]$EicarFileName = "eicar.com",

    # Scheduled task name that will run as SYSTEM (default: create it)
    [string]$ScheduledTaskName = "Lab_SecurityTest_Task",

    # Pauses between steps (seconds) to spread telemetry a bit
    [int]$PauseBetweenStepsSec = 1,

    # Feature toggles (defaults: ON)
    [switch]$EnableWriteEicar = $true,
    [switch]$EnableRunEicarNow = $true,
    [switch]$EnableScheduleEicar = $true,
    [switch]$EnableHiddenPS = $true,
    [switch]$EnableHiddenPS_Encoded = $true,
    [switch]$EnableGuiBurst = $true,
    [switch]$EnableReconBurst = $true,
    [switch]$EnableTempFiles = $true,
    [switch]$EnableRunKey = $true,
    [switch]$EnableRegistryNoise = $true,
    [switch]$EnableCreateScheduledTask = $true,

    # Cleanup toggle - default OFF (you can run with -CleanupAutorun to remove autorun)
    [switch]$CleanupAutorun = $false
)

# ---- helpers ----
function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    Write-Host $line
    $dir = Split-Path $LogPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path $LogPath -Value $line
}

function Ensure-Folder {
    param([string]$Path)
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

# Small helper: TCP connect with timeout (milliseconds). Returns $true if connect succeeded within timeout.
# NOTE: parameter renamed to HostName to avoid colliding with the automatic $Host variable.
function Test-TcpConnectWithTimeout {
    param(
        [Parameter(Mandatory=$true)][string]$HostName,
        [Parameter(Mandatory=$true)][int]$Port,
        [int]$TimeoutMs = 1000
    )
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $iar = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
        $connected = $iar.AsyncWaitHandle.WaitOne($TimeoutMs)
        if ($connected) {
            try { $tcpClient.EndConnect($iar) } catch {}
            try { $tcpClient.Close() } catch {}
            return $true
        } else {
            try { $tcpClient.Close() } catch {}
            return $false
        }
    } catch {
        return $false
    }
}

# ---- start ----
Write-Log "=== LabHarness started ==="
Write-Log "Ensure you are running this in an isolated VM with admin privileges."

Ensure-Folder -Path (Split-Path $LogPath -Parent)
Ensure-Folder -Path $EicarFolder
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 1) write EICAR test file (optional) ----
$eicarString = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicarPath = Join-Path $EicarFolder $EicarFileName

if ($EnableWriteEicar) {
    try {
        Write-Log ("[EICAR] Writing EICAR test file to {0}" -f $eicarPath)
        [System.IO.File]::WriteAllText($eicarPath, $eicarString, [System.Text.Encoding]::ASCII)
        Write-Log "[EICAR] Wrote EICAR file"
    } catch {
        Write-Log ("[EICAR] Failed to write EICAR file: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "[EICAR] Skipped writing EICAR (disabled)"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 2) network recon burst (DNS + HTTP probes) ----
function Do-NetworkProbes {
    param([int]$TcpTimeoutMs = 1000)  # default 1 second
    Write-Log "Starting network probes..."
    $targets = @("example.com","badssl.com","msftconnecttest.com","iana.org","malware-traffic-analysis.net")
    foreach ($t in $targets) {
        Write-Log ("[NET] Resolve {0}" -f $t)
        try {
            Resolve-DnsName -Name $t -ErrorAction Stop | ForEach-Object { Write-Log ("[NET] Resolved {0} -> {1}" -f $t, $_.IPAddress) }
        } catch {
            Write-Log ("[NET] DNS resolve failed for {0}: {1}" -f $t, $_.Exception.Message)
        }
        Start-Sleep -Milliseconds 200

        Write-Log ("[NET] HTTP probe to http://{0} (5s timeout)" -f $t)
        try {
            Invoke-WebRequest -Uri "http://$t" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop | Out-Null
            Write-Log ("[NET] HTTP probe to {0} succeeded" -f $t)
        } catch {
            Write-Log ("[NET] HTTP probe failed for {0}: {1}" -f $t, $_.Exception.Message)
        }
        Start-Sleep -Milliseconds 200
    }

    # Use a short (1s) timeout for the TEST-NET TCP probes so they don't block
    $ips = @("192.0.2.1","198.51.100.1","203.0.113.1")
    foreach ($ip in $ips) {
        Write-Log ("[NET] TCP probe to {0}:80 (timeout {1}ms)" -f $ip, $TcpTimeoutMs)
        try {
            $succeeded = Test-TcpConnectWithTimeout -HostName $ip -Port 80 -TimeoutMs $TcpTimeoutMs
            Write-Log ("[NET] Probe result for {0}: TcpTestSucceeded={1}" -f $ip, $succeeded)
        } catch {
            Write-Log ("[NET] Probe error for {0}: {1}" -f $ip, $_.Exception.Message)
        }
        Start-Sleep -Milliseconds 200
    }

    Write-Log "Network probes done"
}

if ($EnableReconBurst) {
    Do-NetworkProbes -TcpTimeoutMs 1000
} else {
    Write-Log "Network recon burst disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 3) spawn GUI tools (noise / scripted burst) ----
if ($EnableGuiBurst) {
    Write-Log "Starting GUI burst (notepad, mspaint, calc)..."
    $progs = @("notepad.exe","mspaint.exe","calc.exe")
    foreach ($p in $progs) {
        try {
            Start-Process -FilePath $p -ErrorAction SilentlyContinue
            Write-Log ("[GUI] Started {0}" -f $p)
        } catch {
            Write-Log ("[GUI] Could not start {0}: {1}" -f $p, $_.Exception.Message)
        }
        Start-Sleep -Milliseconds 400
    }
} else {
    Write-Log "GUI burst disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 4) hidden PowerShell child (stealth flags) ----
if ($EnableHiddenPS) {
    try {
        Write-Log "Launching hidden PowerShell child with -NoProfile -WindowStyle Hidden"
        $psScript = "Start-Sleep -Seconds 3; Write-Output 'child done'"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -WindowStyle Hidden -Command `$psScript" -WindowStyle Hidden -ErrorAction SilentlyContinue
        Write-Log "Launched hidden PowerShell child"
    } catch {
        Write-Log ("Failed launching hidden PowerShell: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "Hidden PS child disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# Optional: start an encoded command hidden PS to create an encoded-command telemetry artifact
if ($EnableHiddenPS_Encoded) {
    try {
        $cmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("Start-Sleep -Seconds 4; Write-Output 'encoded child'"))
        Start-Process powershell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -EncodedCommand $cmd" -WindowStyle Hidden -ErrorAction SilentlyContinue
        Write-Log "Launched hidden PowerShell via -EncodedCommand"
    } catch {
        Write-Log ("Failed launching encoded PowerShell: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "Hidden PS (encoded) disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 5) temp file write & open (devicefileevents) ----
if ($EnableTempFiles) {
    try {
        $tempFile = Join-Path $env:TEMP ("lab-" + ([guid]::NewGuid().ToString("N")) + ".txt")
        "lab harness temp file `n$(Get-Date)" | Out-File -FilePath $tempFile -Encoding ascii -Force
        Write-Log ("[FILE] Wrote temp file: {0}" -f $tempFile)
        Start-Process notepad.exe $tempFile -ErrorAction SilentlyContinue
        Write-Log ("[FILE] Opened temp file in notepad: {0}" -f $tempFile)
    } catch {
        Write-Log ("[FILE] Temp file step failed: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "Temp file step disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 6) registry noise & autorun (DeviceRegistryEvents) ----
if ($EnableRegistryNoise) {
    try {
        $k = 'HKCU:\Software\LabHarness'
        New-Item -Path $k -Force | Out-Null
        New-ItemProperty -Path $k -Name 'Toggle' -Value ([guid]::NewGuid().ToString()) -PropertyType String -Force | Out-Null
        Write-Log ("[REG] Set LabHarness\\Toggle -> {0}" -f (Get-ItemProperty -Path $k -Name 'Toggle').Toggle)
    } catch {
        Write-Log ("[REG] Registry noise failed: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "Registry noise disabled"
}

if ($EnableRunKey) {
    try {
        $rk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        New-Item -Path $rk -Force | Out-Null
        New-ItemProperty -Path $rk -Name 'LabTelemetry' -Value 'notepad.exe' -PropertyType String -Force | Out-Null
        Write-Log "[REG] Set Run key LabTelemetry -> notepad.exe"
    } catch {
        Write-Log ("[REG] Autorun key set failed: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Log "Autorun Run key disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 7) scheduled task registration to open EICAR (always remove+create) ----
function Create-ScheduledTaskToOpenEicar {
    param($TaskName, $PathToEicar)

    Write-Log ("[TASK] Preparing to create scheduled task '{0}' (will remove existing task if present)" -f $TaskName)

    try {
        # If a task exists with this name, remove it first (silently)
        $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Log ("[TASK] Found existing scheduled task '{0}' - removing it" -f $TaskName)
            try {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
                Write-Log ("[TASK] Removed existing scheduled task '{0}'" -f $TaskName)
            } catch {
                Write-Log ("[TASK] Failed to remove existing task '{0}': {1}" -f $TaskName, $_.Exception.Message)
            }
        } else {
            Write-Log ("[TASK] No existing scheduled task '{0}' found" -f $TaskName)
        }
    } catch {
        Write-Log ("[TASK] Error checking existing scheduled tasks: {0}" -f $_.Exception.Message)
    }

    # Build the action/trigger/principal (task can be registered even if target file doesn't exist)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"Start-Process -FilePath '$PathToEicar' -ErrorAction SilentlyContinue`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Minutes 1)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force
        Write-Log ("[TASK] Registered scheduled task '{0}'" -f $TaskName)
    } catch {
        Write-Log ("[TASK] Failed to register scheduled task: {0}" -f $_.Exception.Message)
    }
}

if ($EnableCreateScheduledTask -and $EnableScheduleEicar) {
    Create-ScheduledTaskToOpenEicar -TaskName $ScheduledTaskName -PathToEicar $eicarPath
} else {
    Write-Log "[TASK] Scheduled task creation disabled"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 8) attempt to open EICAR now (this may be quarantined immediately) ----
if ($EnableRunEicarNow -and (Test-Path $eicarPath)) {
    try {
        Write-Log ("[EICAR] Attempting to open EICAR file now: {0}" -f $eicarPath)
        Start-Process -FilePath $eicarPath -ErrorAction SilentlyContinue
        Write-Log "[EICAR] Launch request sent for EICAR file (Defender may intercept immediately)"
    } catch {
        Write-Log ("[EICAR] Error launching EICAR file: {0}" -f $_.Exception.Message)
    }
} elseif ($EnableRunEicarNow -and -not (Test-Path $eicarPath)) {
    Write-Log "[EICAR] EnableRunEicarNow is true but EICAR file is missing - skipped immediate launch"
} else {
    Write-Log "[EICAR] Skipped immediate EICAR launch"
}
Start-Sleep -Seconds $PauseBetweenStepsSec

# ---- 9) Optional: query local Defender operational log for eicar mentions (best-effort) ----
try {
    Write-Log "[DEF] Querying Defender operational log for EICAR mentions (last 60 events)"
    $events = Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -MaxEvents 60 -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match 'EICAR|eicar' }
    if ($events) {
        foreach ($ev in $events) {
            $short = "{0} | Id:{1} | {2}" -f $ev.TimeCreated, $ev.Id, ($ev.Message -replace "`r`n", ' ')
            Write-Log ("[DEF] Defender event: {0}" -f $short)
        }
    } else {
        Write-Log "[DEF] No matching Defender operational events found in recent slice"
    }
} catch {
    Write-Log ("[DEF] Error reading Defender log: {0}" -f $_.Exception.Message)
}

# ---- final summary & hints ----
Write-Log "=== LabHarness finished. Summary of enabled features ==="
Write-Log ("EnableWriteEicar = {0}" -f $EnableWriteEicar.IsPresent)
Write-Log ("EnableRunEicarNow = {0}" -f $EnableRunEicarNow.IsPresent)
Write-Log ("EnableScheduleEicar = {0}" -f $EnableScheduleEicar.IsPresent)
Write-Log ("EnableHiddenPS = {0}" -f $EnableHiddenPS.IsPresent)
Write-Log ("EnableHiddenPS_Encoded = {0}" -f $EnableHiddenPS_Encoded.IsPresent)
Write-Log ("EnableGuiBurst = {0}" -f $EnableGuiBurst.IsPresent)
Write-Log ("EnableReconBurst = {0}" -f $EnableReconBurst.IsPresent)
Write-Log ("EnableTempFiles = {0}" -f $EnableTempFiles.IsPresent)
Write-Log ("EnableRunKey = {0}" -f $EnableRunKey.IsPresent)
Write-Log ("EnableRegistryNoise = {0}" -f $EnableRegistryNoise.IsPresent)
Write-Log ("EnableCreateScheduledTask = {0}" -f $EnableCreateScheduledTask.IsPresent)
Write-Log "Check telemetry in your EDR (DeviceProcessEvents, DeviceNetworkEvents, DeviceFileEvents, DeviceRegistryEvents, DeviceEvents)."

Write-Host ""
Write-Host "Hint: try these Advanced Hunting queries to find the generated telemetry:"
Write-Host " - PowerShell stealth patterns"
Write-Host " - New destinations / recon burst (DNS+HTTP)"
Write-Host " - Test-net IPs (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24)"
Write-Host " - Registry Run key changes"
Write-Host " - Temp file writes and notepad open"
Write-Host " - Scheduled task creation events"
Write-Host ""

# ---- optional cleanup if requested ----
if ($CleanupAutorun) {
    try {
        Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'LabTelemetry' -ErrorAction SilentlyContinue
        Remove-Item -Path 'HKCU:\Software\LabHarness' -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "[CLEANUP] Removed autorun and LabHarness registry keys"
    } catch {
        Write-Log ("[CLEANUP] Cleanup failed: {0}" -f $_.Exception.Message)
    }
}

Write-Log "=== LabHarness complete. Log: $LogPath ==="
