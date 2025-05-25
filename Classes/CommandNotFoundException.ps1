class CommandNotFoundException : System.Exception {
    CommandNotFoundException([string]$Name, [string]$ExtraMessage) : base(
        "'$Name' is not installed.$($ExtraMessage ? " $ExtraMessage" : '')"
    ) {}
}
