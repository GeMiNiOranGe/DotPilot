---
external help file: DotPilot-help.xml
Module Name: DotPilot
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/New-LayeredDotnetTemplate.md
schema: 2.0.0
---

# New-LayeredDotnetTemplate

## SYNOPSIS
Creates a JSON template for a layered .NET project.

## SYNTAX

```
New-LayeredDotnetTemplate [[-OutputPath] <String>] [[-Architecture] <String>] [[-SolutionName] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The `New-LayeredDotnetTemplate` function generates a JSON template file that can be used as a starting point for creating a layered .NET project.
The template can be customized with different project architectures and solution names.

## EXAMPLES

### EXAMPLE 1
```
New-LayeredDotnetTemplate
```

Output
```
info Template created successfully at: .\Default.template.json
```

Creates the default template in the current directory.

### EXAMPLE 2
```
New-LayeredDotnetTemplate -OutputPath '.\MyProject.template.json' -Architecture Clean -SolutionName 'MyProject'
```

Output
```
info Template created successfully at: .\MyProject.template.json
```

Creates a template with the Clean architecture in the current directory, with the file name "MyProject.template.json" and the solution name "MyProject".

## PARAMETERS

### -OutputPath
Specifies the output path for the generated JSON template file.
If not provided, the file will be created in the current directory with the name "layers.template.json".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Architecture
Specifies the architecture of the layered project.
Currently, the supported value is "Clean", "WinFormsThreeLayers".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SolutionName
Specifies the name of the solution for the layered project.
The default value is "Example".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Example
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You can't pipe objects to `New-LayeredDotnetTemplate`.
## OUTPUTS

### None. This function does not return any output, but it creates a JSON template file with the specified template.
## NOTES
The generated JSON template file will have the following structure:
```json
{
    "solutionName": "Example",
    "layers": [
        {
            "name": "App",
            "type": "webapi",
            "extraArguments": "--use-controllers",
            "packages": [],
            "projectReferences": []
        }
        // define other layers ...
    ]
}
```
The template can be customized by modifying the "layers" array to include the desired project structure and templates.

Property            | Type     | Description
------------------- | -------- | -----------------------------------------------------------------
`name`              | string   | The name of the project.
`type`              | string   | The type of project, `webapi` indicates it's a Web API project.
`extraArguments`    | string   | Additional command-line arguments used when creating the project.
`packages`          | array    | A list of NuGet packages that the project depends on.
`projectReferences` | array    | A list of other projects this project references.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/New-LayeredDotnetTemplate.md)


