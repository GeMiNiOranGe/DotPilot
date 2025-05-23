---
external help file: DotPilot-help.xml
Module Name: DotPilot
online version:
schema: 2.0.0
---

# Initialize-LayeredDotnetProject

## SYNOPSIS
Initializes a layered .NET project based on a JSON template file.

## SYNTAX

```
Initialize-LayeredDotnetProject [-TemplateJsonPath] <String> [-NoDirectoryBuildFile] [-LogToFile]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The `Initialize-LayeredDotnetProject` function creates a new .NET solution and projects based on the template defined in a JSON file.
The function supports creating multiple layers (projects) with different project types and optional NuGet package references.

## EXAMPLES

### EXAMPLE 1
```
Initialize-LayeredDotnetProject -TemplateJsonPath 'C:\Projects\MyProject\template.json'
```

### EXAMPLE 2
```
Initialize-LayeredDotnetProject -TemplateJsonPath 'C:\Projects\MyProject\template.json' -NoDirectoryBuildFile -LogToFile
```

## PARAMETERS

### -TemplateJsonPath
Specifies the path to the JSON template file that defines the solution and project structure.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDirectoryBuildFile
Specifies whether to skip creating the `Directory.Build.props` file.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogToFile
Specifies whether to log the output to a file instead of the console.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### None. You can't pipe objects to `Initialize-LayeredDotnetProject`.
## OUTPUTS

### None. This function does not return any output, but it creates a .NET solution and projects based on the provided template.
## NOTES
The JSON template file should be created using the `New-LayeredDotnetTemplate` command.

## RELATED LINKS

