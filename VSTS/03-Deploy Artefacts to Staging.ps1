param([String]$spSync_SiteCollectionUrl, [String]$spSync_ClientId, [String]$spSync_ClientSecret)

$startFolder = Get-Location;

#Load SharePoint PnP PowerShell module
Import-Module ($startFolder.ToString() + '\SharePointPnPPowerShellOnline\SharePointPnPPowerShellOnline.psd1') -DisableNameChecking;

#Iterate through extensions.
$extensions = ls | where {$_ -is [System.IO.DirectoryInfo]};
$extensions = $extensions | where name -ne SharePointPnPPowerShellOnline;
$extensions | foreach {
	$extensionFolder = $_.FullName;
	Write-Host $_.Name;
	$packageFolder = Join-Path $extensionFolder 'tools';
    $packageScript = Join-Path $packageFolder 'install.ps1';
	Set-Location $packageFolder;
            
    & $packageScript -url $spSync_SiteCollectionUrl -clientId $spSync_ClientId -clientSecret $spSync_ClientSecret;
}

Set-Location $startFolder;