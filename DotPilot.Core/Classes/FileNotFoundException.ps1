class FileNotFoundException : System.IO.FileNotFoundException {
    FileNotFoundException([string]$fullPath, [string]$fileName) `
        : base("File '$fullPath' not found. Ensure that '$fileName' exists.") {}
}
