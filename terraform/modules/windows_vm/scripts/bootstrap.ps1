<powershell>
# Initial configuration script for Windows Server

# Enable WinRM for Ansible
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file

# Firewall configurations for SQL Server
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
New-NetFirewallRule -DisplayName "SQL Server Browser" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow

# Configure Windows to allow Ansible connections
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Create directories for SQL Server
New-Item -Path "C:\SQLData" -ItemType Directory -Force
New-Item -Path "C:\SQLLogs" -ItemType Directory -Force
New-Item -Path "C:\SQLBackup" -ItemType Directory -Force

# Install Windows features necessary for SQL Server
Install-WindowsFeature -Name NET-Framework-Core -Source D:\sources\sxs

# Create a file to indicate bootstrap is complete
New-Item -Path C:\bootstrap_complete.txt -ItemType File -Value
</powershell>
