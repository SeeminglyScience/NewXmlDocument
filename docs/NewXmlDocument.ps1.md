---
external help file:
online version:
schema: 2.0.0
---

# NewXmlDocument.ps1

## SYNOPSIS

Easy DSL for generating XML documents.

## SYNTAX

```powershell
NewXmlDocument.ps1 [-ScriptBlock] <ScriptBlock> [-FilePath <String>] [-Namespace <Object>]
```

## DESCRIPTION

The NewXmlDocument script creates a new XML document using a dynamic DSL (Domain Specific Language).

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
NewXmlDocument.ps1 -FilePath '.\Authors.xml' {
    Authors {
        Author {
            Name = 'John'
            Age = 30
        }
        Author {
            Name = 'Tim'
            Age = 10
            'Writes about horror'
        }
    }
}
```

Produces an XML file with the following content:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Authors>
  <Author Name="John" Age="30" />
  <Author Name="Tim" Age="10">Writes about horror</Author>
</Authors>
```

### -------------------------- EXAMPLE 2 --------------------------

```powershell
$plaster = NewXmlDocument.ps1 -Namespace 'http://www.microsoft.com/schemas/PowerShell/Plaster/v1' {
    plasterManifest {
        schemaVersion = '1.0'
        metadata {
            name { 'TestManifest' }
            id { (New-Guid).Guid }
            version { '0.1.0' }
            title { 'My Plaster Manifest' }
            description { 'A plaster manifest created to test this function.' }
        }
        parameters {
            parameter {
                name = 'ModuleName'
                type = 'Text'
                prompt = 'Enter the name of the module'
            }
        }
        content {
            file {
                source = '_module.psm1'
                destination = '${PLASTER_PARAM_ModuleName}.psd1'
            }
            requireModule {
                name = 'Pester'
                minimumVersion = '3.4.0'
                message = 'Without Pester, you will not be able to run tests!'
            }
        }
    }
}
$plaster.Save('.\plasterManifest.xml')
```

Produces an working plaster manifest XML document with the following content:

```xml
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
```

## PARAMETERS

### -ScriptBlock

Specifies a script block that contains XML elements as command names.

Any command in the script block that does not have a command that is loaded into the current session will be treated as an XML element.

To create an element, use the element name as the command name, and pass a script block as a
argument.

For example, this command would create the XML `<Description>description here</Description>`.

```powershell
Description { 'description here' }
```

You can use any resolvable command, variable, etc to return the value assigned to the element.

To create an attribute, use the same syntax you would in a hashtable definition.

For example, this command

```powershell
Author {
   Name = "Jim"
}
```

Would create the XML `<Author Name="Jim" />`

The syntax for these can be combined and nested to form a full XML document (see examples for more
details)

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath

Specifies the file path to save the XML document to.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Namespace

Specifies the namespace for the XML document. This is the only valid way to define the namespace, if you try to define it with a "xmlns" attribute an exception will be thrown.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

This script does not accept input from the pipeline

## OUTPUTS

### System.Xml.Linq.XElement

The completed XML element will be returned to the pipeline.

## NOTES

The following changes are made to command lookup while the DSL is running:

- Module Autoloading is set to ModuleQualified

- Aliases are disabled

- The "prompt" function is disabled

- Resolving "Get-*" commands with only the noun is disabled

- All command lookup failures are routed to a function in this script

## RELATED LINKS
