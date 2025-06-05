class CliToolNotInstalledException : System.Exception {
    CliToolNotInstalledException([string]$Name, [string]$ExtraMessage) : base(
        "'$Name' is not installed.$($ExtraMessage ? " $ExtraMessage" : '')"
    ) {}
}
