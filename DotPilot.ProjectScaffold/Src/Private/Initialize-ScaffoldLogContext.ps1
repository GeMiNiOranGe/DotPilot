function Initialize-ScaffoldLogContext {
    param (
        [string]$Source,

        [string]$FileName
    )
    $PSDefaultParameterValues['Write-Log:Source'] = $Source

    if ($global:DotPilot.Log.FileLogging) {
        switch ($global:DotPilot.Log.FileFormat) {
            "Log" {
                $PSDefaultParameterValues['Write-Log:File'] = "$FileName.log"
            }
            default {
                throw "Unsupported log file format: $(
                    $global:DotPilot.Log.FileFormat
                )"
            }
        }
    }
}
