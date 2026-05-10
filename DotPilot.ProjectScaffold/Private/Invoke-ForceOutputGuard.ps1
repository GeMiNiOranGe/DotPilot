function Invoke-ForceOutputGuard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [switch]$Force
    )

    if ($Force) {
        $dirPath = [System.IO.Path]::GetDirectoryName($Path)
        if (
            -not [string]::IsNullOrEmpty($dirPath) -and
            -not (Test-Path -Path $dirPath -PathType Container)
        ) {
            [void](New-Item -ItemType Directory -Force $dirPath)
        }
    }
    else {
        Assert-ParentDirectoryExists -Path $Path -Cmdlet $Cmdlet
        Assert-FileNotExists -Path $Path -Cmdlet $Cmdlet
    }
}
