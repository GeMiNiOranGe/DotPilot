class CliToolNotInstalledException : System.Exception {
    hidden static [string] $MessageTemplate = `
        "'{0}' is not installed."

    CliToolNotInstalledException([string]$name) : base(
        ([CliToolNotInstalledException]::MessageTemplate -f $name)
    ) {}

    CliToolNotInstalledException([string]$name, [string]$extraMessage) : base(
        ([CliToolNotInstalledException]::MessageTemplate -f $name) +
        " $extraMessage"
    ) {}
}
