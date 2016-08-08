$startFolder = Get-Location;

#Iterate through extensions.
$extensions = ls | where {$_ -is [System.IO.DirectoryInfo]};
$extensions = $extensions | where name -ne SharePointPnPPowerShellOnline;
$extensions | foreach {
	$extensionFolder = $_.FullName;
	Write-Host $_.Name;
	Set-Location -Path $extensionFolder;
	gulp build
	$packageconfig = (Get-Content './package.json') -join "`n" | ConvertFrom-Json
	$version = $packageconfig.version + '.' + $env:BUILD_BUILDNUMBER;
	 ..\nuget.exe pack -Version $version
}

Set-Location $startFolder;