# "Blank" covers null, empty, and whitespace-only values,
# following the convention used in Apache Commons / Kotlin.
class ArgumentBlankException : System.ArgumentException {
    ArgumentBlankException([string]$name) `
        : base("Argument '-$name' must not be null or empty, or whitespace.") {}
}
