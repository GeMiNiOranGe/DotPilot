class FileNotFoundException : System.IO.FileNotFoundException {
    hidden static [string] $MessageTemplate = `
        "File '{0}' not found. Ensure that '{1}' exists."

    FileNotFoundException([string]$fullPath, [string]$fileName) : base(
        ([FileNotFoundException]::MessageTemplate -f $fullPath, $fileName)
    ) {}

    FileNotFoundException(
        [string]$fullPath,
        [string]$fileName,
        [string]$extraMessage
    ) : base(
        ([FileNotFoundException]::MessageTemplate -f $fullPath, $fileName) +
        " $extraMessage"
    ) {}
}
