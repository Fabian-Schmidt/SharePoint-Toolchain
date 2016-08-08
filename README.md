This describes a toolchain to create SharePoint extensions for SharePoint 2007-2016 & Online.

The example focus on WebPart but I am using it also for UserCustomAction, Ribbon, JSLink and all kinds of other SharePoint customization.

[Office 365 User group Presentation](Development Lifecycle.pptx). 

#Toolchain overview

![Toolchain](img/Toolchain.png?raw=true)

The following describes the setup of the toolchain.
Prerequisite:
* [Visual Studio Code](https://code.visualstudio.com/)
* [TypeScript](https://www.typescriptlang.org/)
* [NodeJS](https://nodejs.org/)
   * [NPM](https://www.npmjs.com/)
   * [Gulp](http://gulpjs.com/)
   * [webpack module bundler](https://webpack.github.io/)
   * [Typings](https://github.com/typings/typings)
   * [Yeoman](http://yeoman.io/)
   * [TypeScript](https://www.npmjs.com/package/typescript)
* SharePoint Online instance for development
* [Visual Studio Team Serivces](https://www.visualstudio.com/products/visual-studio-team-services-vs)
 * [VSTS Package Management Extension](https://marketplace.visualstudio.com/items?itemName=ms.feed)


## Source control structure
The toolchain requires the source control to have the following structre:
```
 / <- Git root
 /dev.* <- Local development settings. Excluded from source control.
 /*.ps1 <- Scripts for team build. See subfolder VSTS for example.
 /SharePointPnPPowerShellOnline/ <- Folder of SharePoint PnP PowerShell module. Used by team built for staging deployment. 
 /<Extension name>/gulpfile.js <- Script for automation tasks. 
 /<Extension name>/package.json <- NodeJS definition. Reference to used packages. Contains version number.
 /<Extension name>/package.nuspec <- NuGet package definition.
 /<Extension name>/webpack.config.js <- Configuration of WebPack.
 /<Extension name>/NuGet_lib/* <- Additional helper libraries for NuGet deployment. Default empty.
 /<Extension name>/NuGet_tools/install.ps1 <- The install script of the extension on customer SharePoint instance.
 /<Extension name>/src/* <- Source code of the extension.
 /<Extension name>/src/index.html <- The start of the web part.
 /<Extension name>/src/<Extension name>.dwp <- The web part definition file.
 /<Extension name>/src/assets/* <- Artefacts used by extension (images).
 /<Extension name>/src/js/index.tsx <- The typescript code of the extension.
```
All extensions are within one git repository. And each extension has his own folder.

## Setup dev machine
The steps required to setup a developer machine.
* Install prerequisite.
   * [Visual Studio Code](https://code.visualstudio.com/)
   * [TypeScript](https://www.typescriptlang.org/)
   * [NodeJS](https://nodejs.org/)
   * ``` npm install -g gulp typings yo webpack```
* Create file ```/dev.json``` with local development settings.

> Example: 
```
{
    "site": "https://contoso.sharepoint.com/sites/Developer-Fabian",
    "authenticationMethod": "ACS",
    "auth_clientId": "00000000-0000-0000-0000-000000000000",
    "auth_clientSecret": "SECRET"
}
```
See [gulp-sharepoint-sync](https://github.com/Fabian-Schmidt/gulp-sharepoint-sync) for how to setup authentication.
Recommendation:
* Use ACS auth with Client Id and Client Secret to SharePoint Online (Office 365).
* Use seperate site collection for each developer.
* Create self sign certificate for localhost in ```/dev.ca.crt```, ```/dev.server.crt``` and ```/dev.server.key```. Add the certificate to the trust of the machine.
   * Example: https://github.com/webpack/webpack-dev-server/tree/master/ssl

## Development cycle
* Yeoman (Node JS - templating tool) to create project based on template.
> Uses [generator-sharepoint-webpart-extension](https://github.com/Fabian-Schmidt/generator-sharepoint-webpart-extension) to start a new project. 
First time install:
```
npm install -g yo
npm install -g https://github.com/Fabian-Schmidt/generator-sharepoint-webpart-extension.git
```
To use template run:
```
Create new folder in GIT repository and open it
yo sharepoint-webpart-extension
``` 
* Writing extension.
> To edit I recommend using VS code.
```
code .
```
To deploy and start live reloding run:
```
gulp watch
```
The gulp script will:
 * Type script compile
 * Combine and minimize files
 * Upload to SharePoint Online
 
* Open the development page in the browser. Add the web part to the page and start coding.
* Check in code to source control.

## VSTS setup (build and release)
As source control system Visual Studio Team Services is used. 
* Create a new project with Git version control.
* Upload the files from the subfolder [VSTS](VSTS/). Rename 'gitignore' to '.gitignore'.
* Setup Team build<br />
 ![Create new build definition](img/VSTS-NewBuildDefinition.png?raw=true)
 * Choose an empty template.
 * Activate 'Continuous integration'.
 * Click 'Create'.
* Source Control VSTS
 * Auto deploy to a SharePoint Online Showcase instance.
 * Release via VSTS Release manager to a package repository.
 * Add Variables

| Name | Value | Secret |
| --- | --- | --- |
| system.debug | false | |
| spSync_SiteCollectionUrl | https://contoso.sharepoint.com/sites/Development-Showcase | |
| spSync_AuthenticationMethod | ACS |  |
| spSync_ClientId | 00000000-0000-0000-0000-000000000000 |  |
| spSync_ClientSecret | SECRET | Yes |
| CI | true | &nbsp; |

See [gulp-sharepoint-sync](https://github.com/Fabian-Schmidt/gulp-sharepoint-sync) for how to setup authentication.
Recommendation:
 Use ACS auth with Client Id and Client Secret.

  * Create the following build steps
    1. PowerShell 01-Download Dependencies.ps1
    2. PowerShell 02-Build Artefacts.ps1
    3. Copy Files
     * Contents: ```*\release\**\*```
     * Target Folder: ```$(build.artifactstagingdirectory)\release```
    4. Publish Artifact
     * Path to Publish: ```$(build.artifactstagingdirectory)\release```
     * Artifact Name: ```Artifact Name```
     * Artifact Type: ```Server```
    5. Copy Publish Artifact
     * Contents: ```*\*.nupkg```
     * Artifact Name: ```Nuget```
     * Artifact Type: ```Server```
    6. PowerShell 03-Deploy Artefacts to Staging.ps1
     * Arguments: ```-spSync_SiteCollectionUrl $(spSync_SiteCollectionUrl) -spSync_ClientId $(spSync_ClientId) -spSync_ClientSecret $(spSync_ClientSecret)```
  * Run the build. There must be at least one extension present in the repository. This will create the output artefacts.


 * Setup Package Feed<br />
 ![Create new Feed](img/VSTS-NewFeed.png?raw=true)
  * Open Package extension
  * Click New Feed
  
 * Setup release definition
  * Choose an empty template.
  * Choose as Source the build definition created in the last step.
  * Create one environment
   * Name ```NuGet Feed```
   * Create the following build steps
    1. NuGet Publisher
     * Path/Pattern to nupkg: ```**\*.nupkg;-:**\packages\**\*.nupkg```
     * Feed type: ```Internal NuGet Feed```
     * Internal Feed URL: ```https://<VSTS-instance>.pkgs.visualstudio.com/DefaultCollection/_packaging/<Feed Name>/nuget/v3/index.json```
     * NuGet Arguments: ```-NonInteractive```
   * Save and run the release. Check afterwards that the package is in the feed.

## Consuming Feed
Prerequisite:
 * Windows 10 or [Windows Management Framework 5.0](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
  * Uses [Package Management](https://github.com/OneGet/oneget)
 * Internet access
 * Access to SharePoint Online target site with Site Collection admin permission.

The usage of the Feed is a two step approach. First the package feed must be registered once. Afterwards the feed can be consumed. The scripts for performing these two steps are static.

The package is in the sub folder [Feed](Feed/).
In consists of
```
CredMan.ps1 <- Used to store credentials secure.
DeployPackage.ps1 <- Script to deploy package from feed.
nuget.exe <- Required, because Windows Package Managmenent contains currently a bug.
RegisterPackageSource.ps1 <- Script to register feed.
```

Initial setup steps:
 * Adjust your feed url in the ```DeployPackage.ps1``` and ```RegisterPackageSource.ps1```
 * Create Feed Credentials<br />
 ![Create Feed Credentials](img/VSTS-FeedCredentials.png?raw=true)
 * Run ```RegisterPackageSource.ps1``` and provide the Feed Credentials.
 
Package deployment steps:
 * Run ```DeployPackage.ps1``` and provide the target SharePoint site collection url.
 * Select the target package from the selection.
 * Provide target SharePoint credentials.


# FAQ
Please raise questions.
