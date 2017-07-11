#requires -Module InvokeBuild -Version 5.1
[CmdletBinding()]
param()

task Publish {
    if (-not (Test-Path $env:USERPROFILE\.PSGallery\apikey.xml)) {
        throw 'Could not find PSGallery API key!'
    }

    $apiKey = (Import-Clixml $env:USERPROFILE\.PSGallery\apikey.xml).GetNetworkCredential().Password
    Publish-Script -Path $PSScriptRoot\NewXmlDocument.ps1 -NuGetApiKey $apiKey -Confirm
}
