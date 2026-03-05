$public = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Public\*.ps1'
    ) -Recurse -ErrorAction Stop
)

foreach ($import in @($public)) {
    try {
        . $import.FullName
    }
    catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename
