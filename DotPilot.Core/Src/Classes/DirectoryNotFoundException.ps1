class DirectoryNotFoundException : System.IO.DirectoryNotFoundException {
    hidden static [string] $MessageTemplate = `
        "Could not find a part of the path '{0}'. Ensure that the directory" + `
        " '{1}' exists."

    DirectoryNotFoundException([string]$fullPath, [string]$directoryName) : base(
        ([DirectoryNotFoundException]::MessageTemplate `
            -f $fullPath, $directoryName
        )
    ) {}

    DirectoryNotFoundException(
        [string]$fullPath,
        [string]$directoryName,
        [string]$extraMessage
    ) : base(
        ([DirectoryNotFoundException]::MessageTemplate `
            -f $fullPath, $directoryName
        ) + " $extraMessage"
    ) {}
}
