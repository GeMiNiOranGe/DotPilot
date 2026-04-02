function Assert-GuardThrew {
    param (
        [System.Management.Automation.ErrorRecord]$CaughtError,
        [string]$Context
    )

    if ($null -ne $CaughtError) {
        return
    }

    throw @(
        "Guard: Invoke-Caller did not throw for $Context - all assertions in "
        "this Context are invalid."
    ) -join ''
}
