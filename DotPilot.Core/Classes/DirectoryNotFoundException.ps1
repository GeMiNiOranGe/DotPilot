class DirectoryNotFoundException : System.IO.DirectoryNotFoundException {
    DirectoryNotFoundException([string]$fullPath, [string]$directoryName) `
        : base(@(
            "Could not find part of the path '$fullPath'. Ensure that the"
            " directory '$directoryName' exists."
        ) -join '') {}
}
