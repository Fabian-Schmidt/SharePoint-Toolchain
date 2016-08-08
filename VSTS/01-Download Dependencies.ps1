$ErrorActionPreference = 'Stop';
if ($env:SYSTEM_DEFAULTWORKINGDIRECTORY) {
	npm config set cache %SYSTEM_DEFAULTWORKINGDIRECTORY%\npm-cache --global
}
#Global dependencies
$ErrorActionPreference = 'Continue';
npm install --global typings typescript webpack 2>.\npm.errors.log
$ErrorActionPreference = 'Stop';
$messages = (Get-Content .\npm.errors.log) 
$errors = $messages | select-string 'ERROR' -AllMatches -CaseSensitive
if ($errors.length -lt 0) {
    Write-Error $messages
}

$startFolder = Get-Location;

#Iterate through extensions.
$extensions = ls | where {$_ -is [System.IO.DirectoryInfo]};
$extensions = $extensions | where name -ne SharePointPnPPowerShellOnline;
$extensions | foreach {
	$extensionFolder = $_.FullName;
	Write-Host $_.Name;
	Set-Location -Path $extensionFolder;
    #run npm
    $ErrorActionPreference = 'Continue';
	npm install 2>.\npm.errors.log
    $ErrorActionPreference = 'Stop';
    $messages = (Get-Content .\npm.errors.log) 
    $errors = $messages | select-string 'ERROR' -AllMatches -CaseSensitive
    if ($errors.length -lt 0) {
        Write-Error $messages
    }
    #run typings
    $ErrorActionPreference = 'Continue';
	typings install 2>.\typings.errors.log
    $ErrorActionPreference = 'Stop';
    $messages = (Get-Content .\typings.errors.log) 
    $errors = $messages | select-string 'ERROR' -AllMatches -CaseSensitive
    if ($errors.length -lt 0) {
        Write-Error $messages
    }
}

Set-Location $startFolder;