class FileAlreadyExistsException : System.IO.IOException {
    FileAlreadyExistsException([string]$filePath) `
        : base("File '$filePath' already exists.") {}
}
