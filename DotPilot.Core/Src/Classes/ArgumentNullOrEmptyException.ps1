class ArgumentNullOrEmptyException : System.ArgumentException {
    ArgumentNullOrEmptyException([string]$name) `
        : base("Argument '-$name' must not be null or empty.") {}
}
