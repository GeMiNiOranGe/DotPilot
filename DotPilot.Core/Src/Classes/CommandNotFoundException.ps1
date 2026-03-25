class CommandNotFoundException `
    : System.Management.Automation.CommandNotFoundException {
    hidden static [string] $MessageTemplate = `
        "'{0}' is not installed or not found in PATH."

    CommandNotFoundException([string]$name) : base(
        ([CommandNotFoundException]::MessageTemplate -f $name)
    ) {}

    CommandNotFoundException([string]$name, [string]$extraMessage) : base(
        ([CommandNotFoundException]::MessageTemplate -f $name) +
        " $extraMessage"
    ) {}
}
