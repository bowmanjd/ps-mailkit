[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Server,
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 587,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("None", "StartTls", "SslOnConnect")]
    [string]$EncryptionType = "StartTls"
)

# Import required assemblies
Add-Type -AssemblyName System

# Try to load MailKit assembly from the installed package
$mailKitPath = Join-Path (Get-Item (Get-Package MailKit).source).Directory lib\net8.0\MailKit.dll
$mimeKitPath = Join-Path (Get-Item (Get-Package MimeKit).source).Directory lib\net8.0\MimeKit.dll

# Function to check if assembly is already loaded
function Test-AssemblyLoaded {
    param (
        [string]$AssemblyName
    )
    
    [System.AppDomain]::CurrentDomain.GetAssemblies() | 
        Where-Object { $_.GetName().Name -eq $AssemblyName } | 
        ForEach-Object { return $true }
    
    return $false
}

# First load MimeKit (dependency)
$mimeKitLoaded = Test-AssemblyLoaded "MimeKit"
if (-not $mimeKitLoaded -and (Test-Path $mimeKitPath)) {
    try {
        Add-Type -Path $mimeKitPath
        $mimeKitLoaded = $true
    }
    catch {
        Write-Host "Failed to load MimeKit: $_" -ForegroundColor Yellow
        $mimeKitLoaded = $false
    }
}

# Then load MailKit
$mailKitLoaded = Test-AssemblyLoaded "MailKit"
if (-not $mailKitLoaded -and (Test-Path $mailKitPath)) {
    try {
        Add-Type -Path $mailKitPath
        $mailKitLoaded = $true
    }
    catch {
        Write-Host "Failed to load MailKit: $_" -ForegroundColor Yellow
        $mailKitLoaded = $false
    }
}
if (-not $mailKitLoaded) {
    Write-Host "MailKit assembly not found at $mailKitPath" -ForegroundColor Yellow
    $mailKitLoaded = $false
}

try {
    if ($mailKitLoaded) {
        # Use MailKit if available
        # Create client
        $client = New-Object MailKit.Net.Smtp.SmtpClient

        # Configure encryption option
        $secureSocketOptions = switch ($EncryptionType) {
            "None" { [MailKit.Security.SecureSocketOptions]::None }
            "StartTls" { [MailKit.Security.SecureSocketOptions]::StartTls }
            "SslOnConnect" { [MailKit.Security.SecureSocketOptions]::SslOnConnect }
        }

        # Connect to the server
        Write-Host "Connecting to $Server on port $Port using $EncryptionType..." -ForegroundColor Cyan
        $client.Connect($Server, $Port, $secureSocketOptions)
        
        # Print authentication mechanisms
        Write-Host "Available Authentication Mechanisms:" -ForegroundColor Green
        $client.AuthenticationMechanisms | ForEach-Object {
            Write-Host "- $_" -ForegroundColor White
        }
    }
    else {
        # Use built-in SmtpClient
        $client = New-Object System.Net.Mail.SmtpClient($Server, $Port)
        
        # Configure encryption
        $client.EnableSsl = $EncryptionType -ne "None"
        
        Write-Host "Connecting to $Server on port $Port using $EncryptionType..." -ForegroundColor Cyan
        
        # Test connection by trying to send a dummy message
        # We're not actually sending anything, just checking if we can connect
        try {
            $client.ServicePoint.ConnectionLimit = 1
            $client.ServicePoint.Expect100Continue = $false
            $client.ServicePoint.UseNagleAlgorithm = $false
            
            Write-Host "Connected to server successfully." -ForegroundColor Green
            Write-Host "Note: With System.Net.Mail.SmtpClient, we cannot enumerate authentication mechanisms." -ForegroundColor Yellow
            Write-Host "Common mechanisms are: PLAIN, LOGIN, NTLM, GSSAPI" -ForegroundColor White
        }
        catch {
            Write-Host "Could not connect: $_" -ForegroundColor Red
        }
    }
}
catch {
    Write-Error "Error: $_"
}
finally {
    # Ensure we disconnect the client if it's connected
    if ($mailKitLoaded -and $client -and $client.IsConnected) {
        $client.Disconnect($true)
        $client.Dispose()
    }
    elseif (-not $mailKitLoaded -and $client) {
        $client.Dispose()
    }
}
