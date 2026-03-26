class CommandNotFoundException `
    : System.Management.Automation.CommandNotFoundException {
    CommandNotFoundException([string]$name) `
        : base("'$name' is not installed or not found in PATH.") {}
}
