function Get-LogSplat {
    param (
        [string]$Source,

        [string]$FileName
    )

    $splat = @{
        Source = $Source
    }

    if (-not $global:DotPilot.Log.FileLogging) {
        return $splat
    }

    switch ($global:DotPilot.Log.FileFormat) {
        "Log"  {
            $splat.File = "$FileName.log"
        }
        default {
            throw "Unsupported log file format: $(
                $global:DotPilot.Log.FileFormat
            )"
        }
    }

    return $splat
}
