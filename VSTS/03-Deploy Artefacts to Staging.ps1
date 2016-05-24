param([String]$spSync_ClientSecret)

$startFolder = Get-Location;

#Iterate through extensions.
$extensions = ls | where {$_ -is [System.IO.DirectoryInfo]};
$extensions | foreach {
	$extensionFolder = $_.FullName;
	Write-Host $_.Name;
	Set-Location -Path $extensionFolder;
	gulp --SPSYNC_CLIENTSECRET=$spSync_ClientSecret uploadOnly
}

Set-Location $startFolder;