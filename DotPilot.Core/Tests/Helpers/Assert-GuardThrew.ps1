function Assert-GuardThrew {
    param (
        [string]$Caller,
        [System.Management.Automation.ErrorRecord]$CaughtError,
        [string]$Context
    )

    if ($null -ne $CaughtError) {
        return
    }

    throw @(
        "Guard: $Caller did not throw for $Context - all assertions in "
        "this Context are invalid."
    ) -join ''
}
