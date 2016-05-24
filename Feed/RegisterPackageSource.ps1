#Install-PackageProvider NuGet -Force


$Uri = 'https://<VSTS-instance>.pkgs.visualstudio.com/DefaultCollection/_packaging/<Feed Name>/nuget/v2'
$credential = Get-Credential -Message 'VSTS package feed password'
$feedName = 'SharePointExtensions';
$PlainPassword = $credential.GetNetworkCredential().Password

$pkgSource = Get-PackageSource -ProviderName NuGet -Name $feedName -ErrorAction SilentlyContinue
# if not exists add to sources via NuGet
if ($pkgSource -eq $null) {
    .\Nuget.exe sources Add -name $feedName -source $Uri -username $credential.UserName  -password $PlainPassword
} else {
    .\Nuget.exe sources Update -Name $feedName -Source $Uri -username $credential.UserName  -password $PlainPassword
}

. .\CredMan.ps1 
$result = Write-Creds $Uri $credential.UserName $PlainPassword