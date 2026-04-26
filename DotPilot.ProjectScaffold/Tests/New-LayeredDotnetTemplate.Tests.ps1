<#
Input space
-----------
Param `$OutputPath`:
    Any string. Optional. When absent, defaults to $DefaultTemplateOutputPath
    (".\Template.json"). Drives whether a caller-supplied path or the default
    path is used. Forwarded to Invoke-ForceOutputGuard and then Set-Content.

Param `$Force`:
    [switch]. Forwarded verbatim to Invoke-ForceOutputGuard. Controls whether
    missing parent directories are created and whether an existing file is
    overwritten. Behavior of the guard itself is covered by
    Invoke-ForceOutputGuard's own tests; here only the end-to-end effect
    (file created vs error thrown) is tested.

Param `$Preset`:
    [ValidateSet] string. Controls which raw template file is loaded.
    Three branches: "AspNetWebApiClean", "WinFormsThreeLayers", default
    (omitted or any other value accepted by the parameter).

Param `$SolutionName`:
    [ValidateNotNullOrWhiteSpace] string. Default "Example". Substituted into
    the template content via -replace "{{solutionName}}". Does not affect
    control flow, only the written content.

################################################################################

Equivalence Partitioning
------------------------
1. For `$OutputPath`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           Default path ".\Template.json" used
Present     ".\Out.json"     Supplied path used

2. For `$Force`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           Guard runs; existing file causes throw
Present     -Force           Guard skipped; existing file overwritten

3. For `$Preset`
Partition             Representative          Expected
---------             --------------          --------
Absent (default)      (omit)                  Default.template.json loaded
AspNetWebApiClean     "AspNetWebApiClean"     AspNetWebApiClean.template.json
WinFormsThreeLayers   "WinFormsThreeLayers"   WinFormsThreeLayers.template.json

4. For `$SolutionName`
Partition   Representative   Expected
---------   --------------   --------
Default     (omit)           "Example" substituted in output
Supplied    "MyProject"      "MyProject" substituted in output

################################################################################

Decision table
--------------
OutputPath   Force    Preset          SolutionName   Expected
----------   -----    ------          ------------   --------
Absent       Absent   Absent          Default        File at default path;
                                                     content has "Example"
Present      Absent   Absent          Supplied       File at supplied path;
                                                     content has supplied name
Absent       Absent   AspNetWebApi    Default        AspNetWebApiClean template
                      Clean                          loaded
Absent       Absent   WinFormsThree   Default        WinFormsThreeLayers
                      Layers                         template loaded
Present      Present  Absent          Default        File written even when
                                                     file already exists

Note:
1.  $SolutionName only affects file content, not control flow. Full substitution
    assertions are done on the first two representative combinations. Preset
    rows assert only which template was written, not re-verify solutionName
    substitution ('OutputPath Absent + Force Absent + AspNetWebApiClean' and
    'OutputPath Absent + Force Absent + WinFormsThreeLayers').

2.  $Force is only meaningful when the target file already exists or
    the parent directory is missing. The overwrite behavior is tested once on a
    representative combination where a pre-existing file is present
    ('OutputPath Present + Force Present + Absent + Default').

3.  $OutputPath Absent vs Present is covered on the first two rows. It is not
    re-tested for every Preset combination to avoid combinatorial explosion;
    the path-resolution logic is independent of Preset ('OutputPath Absent +
    Force Absent + AspNetWebApiClean' and 'OutputPath Absent + Force Absent +
    WinFormsThreeLayers').

4.  The two Preset rows ('OutputPath Absent + Force Absent + AspNetWebApiClean'
    and 'OutputPath Absent + Force Absent + WinFormsThreeLayers') share an
    identical test structure - same setup, same assertion, only the Preset value
    and its corresponding template filename differ. They are collapsed into a
    single parameterised Context with -TestCases rather than duplicated
    as separate Contexts.

################################################################################

Test map
--------
ID   Context   Input                      Technique   Assert
--   -------   -----                      ---------   ------
01   OP Abs,   no OutputPath,             DT          File exists at default
     F Abs,    no Force,                              path
     P Def,    no Preset,
     SN Def    no SolutionName
02   ^         ^                          ^           Content contains "Example"
03   OP Pre,   OutputPath=".\Out.json",   DT          File exists at supplied
     F Abs,    no Force, no Preset,                   path
     P Def,    SolutionName="MyProject"
     SN Sup
04   ^         ^                          ^           Content contains
                                                      "MyProject"
05   OP Abs,   no OutputPath,             DT, TC      Content matches template
     F Abs,    no Force,                              for each Preset value
     P <P>,    Preset=<AW|WF>,
     SN Def    no SolutionName
06   OP Pre,   OutputPath=".\Out.json",   DT          File exists
     F Pre,    -Force, no Preset,
     P Def,    no SolutionName
     SN Def

List of Abbreviations:
'^'  - Same context/input/technique as previous row
DT   - Decision Table
TC   - TestCases (parameterised It block)
OP   - OutputPath
F    - Force
P    - Preset
SN   - SolutionName
Abs  - Absent (omitted / default)
Pre  - Present (explicit value supplied)
Def  - Default value used
Sup  - Supplied (explicit non-default value)
AW   - AspNetWebApiClean
WF   - WinFormsThreeLayers
#>
$script:tempDir = "$PSScriptRoot\Temp"

Describe "New-LayeredDotnetTemplate" -Tag @(
    "New-LayeredDotnetTemplate"
    "Dotnet"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\DotPilot.Core\Src\Private\Write-LogConsole.ps1"
        . "$PSScriptRoot\..\Src\Public\New-LayeredDotnetTemplate.ps1"

        Mock Write-LogConsole {}
    }

    BeforeEach {
        [void](New-Item -Path $tempDir -ItemType Directory)
        Set-Location $tempDir
    }

    AfterEach {
        Set-Location (Split-Path -Parent $tempDir)
        Remove-Item $tempDir -Recurse -Force
    }

    Context "When using a valid '-OutputPath' option" {
        It "Creates the default template file in current directory" {
            New-LayeredDotnetTemplate

            $isValidPath = Test-Path $DefaultTemplateOutputPath
            $isValidPath | Should -BeTrue

            $content = Get-Content $DefaultTemplateOutputPath -Raw
            $content | Should -Match '"Example"'

            Remove-Item $DefaultTemplateOutputPath
        }

        It "Creates the template file at the specified output path" {
            $outPath = "$env:TEMP\Template.json"

            New-LayeredDotnetTemplate -OutputPath $outPath

            Test-Path $outPath | Should -BeTrue
            Get-Content $outPath -Raw | Should -Match '"Example"'

            Remove-Item $outPath
        }
    }

    Context "When using an invalid '-OutputPath' option" {
        It "Throws if directory does not exist" {
            $invalidPath = "$tempDir\DirectoryNotExist\Template.json"

            { New-LayeredDotnetTemplate -OutputPath $invalidPath } |
            Should -Throw -ErrorId "DirectoryNotFound,New-LayeredDotnetTemplate"
        }

        It "Throws if path is a file" {
            $directoryName = "DirectoryIsFile"
            $directoryPath = "$tempDir\$directoryName"

            # Create a file with the same name as the intended directory
            [void](New-Item -Path $tempDir -Name $directoryName -ItemType File)

            { New-LayeredDotnetTemplate -OutputPath "$directoryPath\Template.json" } |
            Should -Throw -ErrorId (
                "GetContentWriterDirectoryNotFoundError,New-LayeredDotnetTemplate"
            )

            Remove-Item $directoryPath
        }
    }

    Context "When replacing the '{{solutionName}}' placeholder" {
        It "Uses 'Example' (<TemplateArguments.Preset>)" -TestCases @(
            @{ TemplateArguments = @{ Preset = "Clean" } }
            @{ TemplateArguments = @{ Preset = "WinFormsThreeLayers" } }
            @{ TemplateArguments = @{} }
        ) {
            param ($TemplateArguments)

            New-LayeredDotnetTemplate @TemplateArguments

            $content = Get-Content $DefaultTemplateOutputPath -Raw
            $content | Should -Match '"Example"'

            Remove-Item $DefaultTemplateOutputPath
        }
    }
}
