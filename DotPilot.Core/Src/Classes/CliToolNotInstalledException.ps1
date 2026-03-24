class CliToolNotInstalledException : System.Exception {
    hidden static [string] $MessageTemplate = `
        "'{0}' is not installed."

    CliToolNotInstalledException([string]$Name) : base(
        [CliToolNotInstalledException]::MessageTemplate -f $Name
    ) {}

    CliToolNotInstalledException([string]$Name, [string]$ExtraMessage) : base(
        "$([CliToolNotInstalledException]::MessageTemplate -f $Name) $ExtraMessage"
    ) {}
}
