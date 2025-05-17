class ConsoleCallException : System.Exception {
    ConsoleCallException([string]$funcName) `
        : base("$funcName : Cannot be called from the console.") {}
}
