function New-LayeredDotnetTemplate {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrWhiteSpace()]
        [string]$OutputPath,

        [ValidateSet("Clean")]
        [string]$Architecture,

        [ValidateNotNullOrWhiteSpace()]
        [string]$SolutionName = "Example"
    )
    $targetOutputPath = $OutputPath ? $OutputPath : ".\layers.template.json"
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
    $templateContent = Get-Content -Raw `
        -Path "$PSScriptRoot\..\Template\Dotnet\$template"
    $templateContent = $templateContent -replace "{{solutionName}}", $SolutionName

    Set-Content -Path $targetOutputPath -Value $templateContent
    Write-ConsoleLog Info "Template created successfully at: $targetOutputPath"
}
