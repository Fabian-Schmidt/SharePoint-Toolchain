$ErrorActionPreference = 'Stop';
if ($env:SYSTEM_DEFAULTWORKINGDIRECTORY) {
	npm config set cache %SYSTEM_DEFAULTWORKINGDIRECTORY%\npm-cache --global
}
#Global dependencies
npm install --global typings typescript

$startFolder = Get-Location;

#Iterate through extensions.
$extensions = ls | where {$_ -is [System.IO.DirectoryInfo]};
$extensions | foreach {
	$extensionFolder = $_.FullName;
	Write-Host $_.Name;
	Set-Location -Path $extensionFolder;
    $ErrorActionPreference = 'Continue';
	npm install 2>.\npm.errors.log
    $ErrorActionPreference = 'Stop';
    $messages = (Get-Content .\npm.errors.log) 
    $errors = $messages | select-string 'ERROR' -AllMatches -CaseSensitive
    if ($errors.length -lt 0) {
        Write-Error $messages
    }
	bower install --config.interactive=false
	typings install
}

Set-Location $startFolder;