class ConsoleCallException : System.Exception {
    ConsoleCallException() : base("Cannot be called from the console.") {}
}
