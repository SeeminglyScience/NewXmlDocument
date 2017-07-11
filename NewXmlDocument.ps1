
<#PSScriptInfo

.VERSION 0.1.0

.GUID 1bb4d587-0d89-4ad0-91e1-38bf9ef1cc84

.AUTHOR Patrick Meinecke

.COMPANYNAME Community

.COPYRIGHT (c) 2017 Patrick Meinecke. All rights reserved.

.TAGS XML, DSL, Document

.LICENSEURI https://github.com/SeeminglyScience/NewXmlDocument/blob/master/LICENSE

.PROJECTURI https://github.com/SeeminglyScience/NewXmlDocument

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

#requires -Version 5.1

<#
.SYNOPSIS
 Easy DSL for generating XML documents.

.DESCRIPTION
 The NewXmlDocument script creates a new XML document using a dynamic DSL (Domain Specific Language).

.PARAMETER ScriptBlock
 Specifies a script block that contains XML elements as command names.  Any command in the script block
 that does not have a command that is loaded into the current session will be treated as an XML element.

 To create an element, use the element name as the command name, and pass a script block as a
 argument.

 For example, this command would create the XML "<Description>description here</Description>".

 Description { 'description here' }

 You can use any resolvable command, variable, etc to return the value assigned to the element.

 To create an attribute, use the same syntax you would in a hashtable definition.

 For example, this command

 Author {
    Name = "Jim"
 }

 Would create the XML <Author Name="Jim" />

 The syntax for these can be combined and nested to form a full XML document (see examples for more
 details)

.PARAMETER Namespace
 Specifies the namespace for the XML document. This is the only valid way to define the namespace,
 if you try to define it with a "xmlns" attribute an exception will be thrown.

.PARAMETER FilePath
 Specifies the file path to save the XML document to.

.PARAMETER PassThru
 If specified with the "FilePath" parameter, the XElement will be returned to the pipeline as well
 as written to XML. This parameter has no effect if "FilePath" is not present.

.INPUTS
 None

 This script does not accept input from the pipeline

.OUTPUTS
 System.Xml.Linq.XElement

 The completed XML element will be returned to the pipeline.

.EXAMPLE
 PS C:\> $xml = NewXmlDocument.ps1 -FilePath '.\Authors.xml' {
 >>    Authors {
 >>        Author {
 >>            Name = 'John'
 >>            Age = 30
 >>        }
 >>        Author {
 >>            Name = 'Tim'
 >>            Age = 10
 >>            'Writes about horror'
 >>        }
 >>    }
 >>}

 Produces an XML file with the following content:

 <?xml version="1.0" encoding="utf-8"?>
 <Authors>
   <Author Name="John" Age="30" />
   <Author Name="Tim" Age="10">Writes about horror</Author>
 </Authors>

.EXAMPLE

 PS C:\> $plaster = NewXmlDocument.ps1 -Namespace 'http://www.microsoft.com/schemas/PowerShell/Plaster/v1' {
 >>    plasterManifest {
 >>        schemaVersion = '1.0'
 >>        metadata {
 >>            name { 'TestManifest' }
 >>            id { (New-Guid).Guid }
 >>            version { '0.1.0' }
 >>            title { 'My Plaster Manifest' }
 >>            description { 'A plaster manifest created to test this function.' }
 >>        }
 >>        parameters {
 >>            parameter {
 >>                name = 'ModuleName'
 >>                type = 'Text'
 >>                prompt = 'Enter the name of the module'
 >>            }
 >>        }
 >>        content {
 >>            file {
 >>                source = '_module.psm1'
 >>                destination = '${PLASTER_PARAM_ModuleName}.psd1'
 >>            }
 >>            requireModule {
 >>                name = 'Pester'
 >>                minimumVersion = '3.4.0'
 >>                message = 'Without Pester, you will not be able to run tests!'
 >>            }
 >>        }
 >>    }
 >>}
 PS C:\> $xml.Save('.\plasterManifest.xml')

 Produces an working plaster manifest XML document with the following content:

 <?xml version="1.0" encoding="utf-8"?>
 <plasterManifest schemaVersion="1.0" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
   <metadata>
     <name>TestManifest</name>
     <id>3598072f-578d-42f7-b576-101cadc5efce</id>
     <version>0.1.0</version>
     <title>My Plaster Manifest</title>
     <description>A plaster manifest created to test this function.</description>
   </metadata>
   <parameters>
     <parameter name="ModuleName" type="Text" prompt="Enter the name of the module" />
   </parameters>
   <content>
     <file source="_module.psm1" destination="${PLASTER_PARAM_ModuleName}.psd1" />
     <requireModule name="Pester" minimumVersion="3.4.0" message="Without Pester, you will not be able to run tests!" />
   </content>
 </plasterManifest>

.NOTES

 The following changes are made to command lookup while the DSL is running:

 - Module Autoloading is set to ModuleQualified

 - Aliases are disabled

 - The "prompt" function is disabled

 - Resolving "Get-*" commands with only the noun is disabled

 - All command lookup failures are routed to a function in this script

#>
using assembly System.Xml.Linq

[CmdletBinding(PositionalBinding = $false)]
[OutputType('System.Xml.Linq.XElement')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [scriptblock]
    $ScriptBlock,

    [ValidateNotNullOrEmpty()]
    [Alias('Path')]
    [string]
    $FilePath,

    $Namespace
)
begin {
#region New-XmlElement
    function New-XmlElement {
        [CmdletBinding(DefaultParameterSetName='Body')]
        [OutputType('System.Xml.Linq.XElement', ParameterSetName='Element')]
        [OutputType('System.Xml.Linq.XAttribute', ParameterSetName='Attribute')]
        param(
            [Parameter(Position = 0, Mandatory, ParameterSetName='Element')]
            [scriptblock]
            $Body,

            [Parameter(Position = 0, Mandatory, ParameterSetName='Attribute')]
            [ValidateSet('=')]
            [string]
            $Operator,

            [Parameter(Position = 1, Mandatory, ParameterSetName='Attribute')]
            [string]
            $Text

        )
        end {
            $elementName = [System.Xml.Linq.XName]($MyInvocation.InvocationName)
            if ($Namespace) {
                $elementName = [System.Xml.Linq.XNamespace]$Namespace + $elementName
            }
            switch ($PSCmdlet.ParameterSetName) {
                Attribute {
                    [System.Xml.Linq.XAttribute]::new($MyInvocation.InvocationName, $Text)
                }
                Element {
                    if ($Body -and ($output = . $Body)) {
                        $element = [System.Xml.Linq.XElement]::new($elementName)
                        foreach ($item in $output) {
                            $element.Add($item)
                        }
                        $element
                    } else {
                        [System.Xml.Linq.XElement]::new($elementName)
                    }
                }
            }
        }
    }
#endregion
}
end {
    try {
        # Disable module autoloading so command lookup doesn't take forever to fail.
        $originalPreference = $PSModuleAutoLoadingPreference
        $PSModuleAutoLoadingPreference = 'ModuleQualified'

        # Add post lookup action to override some command lookup results
        $originalPCLA = $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction
        $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
            param(
                [string]
                $commandName,

                [System.Management.Automation.CommandLookupEventArgs]
                $lookupEventArgs
            )

            # Command lookup will prepend Get when looking up verbless commands.
            $isPrependedGet = $lookupEventArgs.Command.Name -match 'Get-(\w+)' -and
                                $Matches[1] -eq $commandName

            # Skip aliases
            $isAlias ='Alias' -eq $lookupEventArgs.Command.CommandType

            # Skip the commands that don't fit Noun-Verb format.
            $isNonStandardFormat = $lookupEventArgs.Command.Name -notmatch '\w+-\w+'

            if ($isPrependedGet -or $isAlias -or $isNonStandardFormat) {
                $lookupEventArgs.Command = $ExecutionContext.SessionState.InvokeCommand.GetCommand(
                    'New-XmlElement',
                    'Function')
            }
        }

        # Add command not found action that returns New-XmlElement for any command lookup failures
        $originalCNFA = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
        $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
            param(
                [string]
                $commandName,

                [System.Management.Automation.CommandLookupEventArgs]
                $lookupEventArgs
            )
            $lookupEventArgs.Command = $ExecutionContext.SessionState.InvokeCommand.GetCommand(
                'New-XmlElement',
                'Function')
        }

        # Any unknown commands in the script block will be treated as XML elements.
        $xml = $ScriptBlock.Invoke()

        if (-not $xml) { return }

        if ($FilePath) {
            try {
                $resolved = $PSCmdlet.SessionState.Path.
                    GetUnresolvedProviderPathFromPSPath($FilePath)

                $xml.Save($resolved)
            } catch {
                $exception = $PSItem -as [Exception]
                if (-not $exception) { $exception = $PSItem.Exception }
                if (-not $exception) { $exception = $PSItem.InnerException }
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'FailureSavingXml',
                        [System.Management.Automation.ErrorCategory]::WriteError,
                        $FilePath))
            }
        }

        if (-not $FilePath -or $PassThru.IsPresent) {
            $xml # yield
        }
    } finally {
        $PSModuleAutoLoadingPreference = $originalPreference
        $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $originalCNFA
        $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = $originalPCLA
    }
}
