function New-LayeredDotnetTemplate {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrWhiteSpace()]
        [string]$OutputPath
    )

    $template = @'
{
    "solutionName": "MySolution",
    "layers": [
        {
            "name": "LayerOne",
            "type": "classlib"
        },
        {
            "name": "LayerTwo",
            "type": "classlib",
            "projects": [
                "LayerOne"
            ]
        },
        {
            "name": "LayerThree",
            "type": "webapi",
            "extraArguments": "--use-controllers",
            "packages": [
                "NSwag.AspNetCore",
                "Scalar.AspNetCore"
            ],
            "projects": [
                "LayerThree"
            ]
        }
    ]
}
'@
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

    Set-Content -Path $targetOutputPath -Value $template
    Write-ConsoleLog Info "Template created successfully at: $targetOutputPath"
}
