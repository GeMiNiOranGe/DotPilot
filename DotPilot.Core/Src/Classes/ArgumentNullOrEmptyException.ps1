class ArgumentNullOrEmptyException : System.ArgumentException {
    hidden static [string] $MessageTemplate = `
        "Argument '-{0}' must not be null or empty."

    ArgumentNullOrEmptyException([string]$Name) : base(
        [ArgumentNullOrEmptyException]::MessageTemplate -f $Name
    ) {}

    ArgumentNullOrEmptyException([string]$Name, [string]$ExtraMessage) : base(
        "$([ArgumentNullOrEmptyException]::MessageTemplate -f $Name) $ExtraMessage"
    ) {}
}
