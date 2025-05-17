function Test-WhiteSpace {
    param (
        [string]$Value
    )

    for ($i = 0; $i -lt $Value.Length; $i++) {
        if (![char]::IsWhiteSpace($Value[$i])) {
            return $false
        }
    }

    return $true
}
