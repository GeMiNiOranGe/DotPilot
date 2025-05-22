function New-LayeredDotnetTemplate {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrWhiteSpace()]
        [string]$SolutionName = "Example",

        [ValidateSet("Clean")]
        [string]$Architecture,

        [ValidateNotNullOrWhiteSpace()]
        [string]$OutputPath
    )
    $targetOutputPath = `
        if ($OutputPath) { $OutputPath } `
        else { ".\layers.template.json" }
    $directory = [System.IO.Path]::GetDirectoryName($targetOutputPath)

    if ($directory -ne "" -and -not (Test-Path $directory)) {
        $exception = [System.IO.DirectoryNotFoundException]::new(
            "The directory '$directory' does not exist."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "DirectoryNotFound",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $OutputPath
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $template = switch ($Architecture) {
        "Clean" {
            "CleanArchitecture.template.json"
            break
        }
        default {
            "DefaultLayers.template.json"
            break
        }
    }
    $templatePath = Resolve-Path -Path "$PSScriptRoot\..\Template\Dotnet\$template"
    $templateContent = Get-Content -Raw -Path $templatePath
    $templateContent = $templateContent -replace "{{solutionName}}", $SolutionName

    Set-Content -Path $targetOutputPath -Value $templateContent
    Write-ConsoleLog Info "Template created successfully at: $targetOutputPath"
}
