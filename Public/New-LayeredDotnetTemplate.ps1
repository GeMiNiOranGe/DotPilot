function New-LayeredDotnetTemplate {
    [CmdletBinding()]
    param (
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

    Copy-Item -Path $templatePath -Destination $targetOutputPath
    Write-ConsoleLog Info "Template created successfully at: $targetOutputPath"
}
