class ArgumentNullOrEmptyException : System.ArgumentException {
    hidden static [string] $MessageTemplate = `
        "Argument '-{0}' must not be null or empty."

    ArgumentNullOrEmptyException([string]$name) : base(
        ([ArgumentNullOrEmptyException]::MessageTemplate -f $name)
    ) {}

    ArgumentNullOrEmptyException([string]$name, [string]$extraMessage) : base(
        ([ArgumentNullOrEmptyException]::MessageTemplate -f $name) +
        " $extraMessage"
    ) {}
}
