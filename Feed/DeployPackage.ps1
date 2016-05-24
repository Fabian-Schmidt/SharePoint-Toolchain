param(
	 [Parameter(Mandatory=$True)][string]$url
	,[Parameter(Mandatory=$False)][string]$username
	,[Parameter(Mandatory=$False)][string]$password
    ,[Parameter(Mandatory=$False)][System.Management.Automation.PSCredential]$credential)
$ErrorActionPreference = 'Stop';
Add-Type -assembly 'System.IO.Compression.Filesystem'

$pkgSource = Get-PackageSource -ProviderName NuGet -Name $feedName -ErrorAction SilentlyContinue
if ($pkgSource -eq $null) {
    .\RegisterPackageSource.ps1
} else {

    $Uri = 'https://<VSTS-instance>.pkgs.visualstudio.com/DefaultCollection/_packaging/<Feed Name>/nuget/v2'
	$feedName = 'SharePointExtensions';
    . .\CredMan.ps1 

    # may be [PsUtils.CredMan+Credential] or [Management.Automation.ErrorRecord] 
    [Object] $Cred = Read-Creds $Uri 
    if($null -eq $Cred) 
    { 
        Write-Host "Credential for '$Target' as '$CredType' type was not found." 
        return 
    } 
    if($Cred -is [Management.Automation.ErrorRecord]) 
    { 
        return $Cred 
    }
    $SecurePassword = ConvertTo-SecureString $Cred.CredentialBlob -AsPlainText -Force
    $PackCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $Cred.UserName, $SecurePassword
    
    $packagesToInstall = Find-Package -Source $feedName -Credential $PackCredential | Out-GridView -PassThru -Title 'Select packages to deploy.'
    if (-not $packagesToInstall){
        Write-Host 'No packages selected.'
    } else {
        $startLocation = Get-Location;
        $tempFolder = Join-Path $env:TEMP 'ExtensionInstall';
        [void][System.IO.Directory]::CreateDirectory($tempFolder);

        $packagesToInstall | ForEach {
            $package = $_;
            $nugetFile = Join-Path $tempFolder $package.PackageFilename;
            #if (-not(Test-Path $nugetFile)) {
                $nuget = Save-Package -Name $package.Name -Source $package.Source -Credential $PackCredential -Path $tempFolder
            #}
            $packageFolder = $nuget.Name + '.' + $nuget.Version
            $packageFolder = Join-Path $tempFolder $packageFolder;
            if (Test-Path $packageFolder) {
                [System.IO.Directory]::Delete($packageFolder, $true);
            }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($nugetFile, $packageFolder);
            $packageFolder = Join-Path $packageFolder 'tools';
            $packageScript = Join-Path $packageFolder 'install.ps1';
            Set-Location $packageFolder;
            
            & $packageScript -url $url -username $username -password $password -credential $credential;
            
            Set-Location $startLocation;
            [System.IO.Directory]::Delete($packageFolder, $true);
        }

        Set-Location $startLocation;
    }
}