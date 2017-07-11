# NewXmlDocument

NewXmlDocument is a PowerShell script that allows you to utilize a dynamic DSL (Domain Specific Language) to create new XML documents.

## Features

- Use hashtable syntax for defining attributes
- Use command syntax for defining elements
- Mix and match in the same ScriptBlock

## Installation

```powershell
Install-Script NewXmlDocument -Scope CurrentUser
```

## Motivation

This project was mainly created as a proof of concept for creating dynamic DSLs using the `CommandNotFoundAction` property of `$ExecutionContext.SessionState.InvokeCommand`. Outside of that it's pretty handy if you don't like working with XML.

## Examples

### Generic XML document

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

### Plaster Manifest

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

### Format Ps1Xml

```powershell
NewXmlDocument.ps1 -FilePath something.format.ps1xml {
    # Piping 0 here is a bit of a hack to get around the Configuration keyword.
    0 | Configuration {
        ViewDefinitions {
            View {
                Name { 'System.RuntimeType' }
                ViewSelectedBy {
                    TypeName { 'System.RuntimeType' }
                }
                TableControl {
                    TableHeaders {
                        TableColumnHeader { Width { 10 }}
                        TableColumnHeader { Label { 'Members' } }
                    }
                    TableRowEntries {
                        TableRowEntry {
                            TableColumnItems {
                                TableColumnItem {
                                    PropertyName { 'Name' }
                                }
                                TableColumnItem {
                                    ScriptBlock { '$_.DeclaredMembers.Name -join ", "' }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

Creates a working format.ps1xml file with the following contents:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
  <ViewDefinitions>
    <View>
      <Name>System.RuntimeType</Name>
      <ViewSelectedBy>
        <TypeName>System.RuntimeType</TypeName>
      </ViewSelectedBy>
      <TableControl>
        <TableHeaders>
          <TableColumnHeader>
            <Width>10</Width>
          </TableColumnHeader>
          <TableColumnHeader>
            <Label>Members</Label>
          </TableColumnHeader>
        </TableHeaders>
        <TableRowEntries>
          <TableRowEntry>
            <TableColumnItems>
              <TableColumnItem>
                <PropertyName>Name</PropertyName>
              </TableColumnItem>
              <TableColumnItem>
                <ScriptBlock>$_.DeclaredMembers.Name -join ", "</ScriptBlock>
              </TableColumnItem>
            </TableColumnItems>
          </TableRowEntry>
        </TableRowEntries>
      </TableControl>
    </View>
  </ViewDefinitions>
</Configuration>
```
