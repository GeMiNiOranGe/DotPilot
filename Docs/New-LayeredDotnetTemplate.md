---
external help file: DotPilot-help.xml
Module Name: DotPilot
online version:
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

### EXAMPLE 2
```
New-LayeredDotnetTemplate -OutputPath 'C:\Projects\MyProject\template.json' -Architecture Clean -SolutionName 'MyProject'
```

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
Currently, the only supported value is "Clean".

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
            "name": "LayerOne",
            "type": "classlib"
        },
        {
            "name": "LayerTwo",
            "type": "classlib",
            "extraArguments": [
                "--framework", "net6.0"
            ],
            "projectReferences": [
                "LayerOne"
            ]
        },
        {
            "name": "LayerThree",
            "type": "webapi",
            "extraArguments": "",
            "packages": [],
            "projectReferences": [
                "LayerThree"
            ]
        }
    ]
}
```
The template can be customized by modifying the "layers" array to include the desired project structure and templates.

## RELATED LINKS

