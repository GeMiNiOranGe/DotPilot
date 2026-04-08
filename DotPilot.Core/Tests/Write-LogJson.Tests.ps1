<#
Input space
-----------
$Level  : [LogLevel] enum. Drives the "Level" field written to the JSON entry.
          Four valid values: Info, Warn, Error, Debug. Each value maps to its
          string name in the serialised output.
$Message: Any string. Written to the "Message" field of the JSON entry. Does not
          affect control flow or Level serialisation. No partitioning needed
          beyond confirming it appears in the output.
$Source : Any string. When non-whitespace, adds a "Source" key to the ordered
          hashtable before serialisation. When absent or whitespace, the key
          is omitted entirely. $null is coerced to "" by PowerShell's [string]
          binding and fails ValidateNotNullOrWhiteSpace, so it is not a valid
          domain value; no duplicate partition needed.
$Path   : Mandatory string, ValidateNotNullOrWhiteSpace. Passed directly to
          Add-Content. Does not affect the JSON entry format. No partitioning
          needed beyond confirming Add-Content receives it.

################################################################################

Equivalence Partitioning
------------------------
1. For `$Level`
Partition   Representative      Expected
---------   --------------      --------
Info        [LogLevel]::Info    JSON contains "Level":"Info"
Warn        [LogLevel]::Warn    JSON contains "Level":"Warn"
Error       [LogLevel]::Error   JSON contains "Level":"Error"
Debug       [LogLevel]::Debug   JSON contains "Level":"Debug"

Note: All four partitions follow the same code path (.ToString() on the
enum); testing all four validates the full label map.

2. For `$Source`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           JSON has no "Source" key
Present     "Verb-Noun"      JSON contains "Source":"Verb-Noun"

################################################################################

Decision table
--------------
$Level   $Source   Expected
------   -------   --------
Info     Absent    Compact JSON: Timestamp, Level "Info", Message, no Source
Info     Present   Compact JSON: Timestamp, Level "Info", Message, Source
Warn     Absent    Compact JSON: Level "Warn"
Error    Absent    Compact JSON: Level "Error"
Debug    Absent    Compact JSON: Level "Debug"

Note:
1.  The Timestamp field format is structural and identical across all
    rows; it is verified once on a representative combination rather
    than repeated on every row ('Info + Absent').

2.  The $Path value passed to Add-Content does not vary across $Level or
    $Source combinations; it is asserted once on a representative
    combination ('Info + Absent').

3.  The Message field appears in the output regardless of $Level or
    $Source. It is verified once on a representative combination
    ('Info + Absent').

4.  The absence of a Source key is asserted once on a representative
    combination ('Info + Absent'); presence is asserted on
    ('Info + Present').

5.  The JSON is compact (no whitespace between tokens). This structural
    property is verified once on a representative combination
    ('Info + Absent').

################################################################################

Test map
--------
ID   Context     Input                Technique   Assert
--   -------     -----                ---------   ------
01   INF + Abs   Info,                DT          Add-Content called once
                 "Server started",
                 path
02   INF + Abs   ^                    ^           Path arg = test path
03   INF + Abs   ^                    ^           Value ~ timestamp pattern
04   INF + Abs   ^                    ^           Contains "Level":"Info"
05   INF + Abs   ^                    ^           Contains "Message":"..."
06   INF + Abs   ^                    ^           Value has no "Source" key
07   INF + Abs   ^                    ^           Value is compact JSON
08   INF + Pre   Info,                DT          Contains "Source":"Verb-Noun"
                 "Server started",
                 "Verb-Noun", path
09   WRN + Abs   Warn, "Disk low",    DT          Contains "Level":"Warn"
                 path
10   ERR + Abs   Error, "Disk low",   DT          Contains "Level":"Error"
                 path
11   DBG + Abs   Debug, "Disk low",   DT          Contains "Level":"Debug"
                 path

List of Abbreviations:
'^'  - Same input/technique as previous row
DT   - Decision Table
INF  - Info
WRN  - Warn
ERR  - Error
DBG  - Debug
Abs  - Absent
Pre  - Present
#>
Describe "Write-LogJson" -Tag "Write-LogJson", "Write-Log*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogJson.ps1"

        Mock Get-Date {
            return "2000-01-01T12:00:00"
        }

        function Get-FirstLogEntry {
            param([string]$Path)
            return Get-Content $Path | Select-Object -First 1 | ConvertFrom-Json
        }
    }

    BeforeEach {
        $script:logFile = Join-Path $TestDrive "test.jsonl"
    }

    AfterEach {
        if ($script:logFile -and (Test-Path $script:logFile)) {
            Remove-Item $script:logFile
        }
    }

    Context "File handling" {
        It "Creates log file when it does not exist" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $script:logFile | Should -Exist
        }

        It "Appends entries to existing log file" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 2
        }
    }

    Context "Log entry format" {
        It "Each line is valid JSON" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            { $firstLine | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Each line is a single line (no pretty-print)" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 1
        }

        It "Contains Timestamp field" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Timestamp | Should -Not -BeNullOrEmpty
        }

        It "Timestamp matches expected format" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '"Timestamp":"2000-01-01T12:00:00"'
        }

        It "Contains the message" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Message | Should -Be "A test message"
        }

        It "Contains level '<Level>' in PascalCase" -TestCases @(
            @{ Level = "Info"; Expected = "Info" }
            @{ Level = "Warn"; Expected = "Warn" }
            @{ Level = "Error"; Expected = "Error" }
            @{ Level = "Debug"; Expected = "Debug" }
        ) {
            Write-LogJson `
                -Level $Level `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Level | Should -Be $Expected
        }

        It "Has correct field order: Timestamp, Level, Message" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '"Timestamp".+"Level".+"Message"'
        }

        It "Has correct field order: Timestamp, Level, Message, Source when Source is provided" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Source "MyFunction" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '"Timestamp".+"Level".+"Message".+"Source"'
        }
    }

    Context "Source field" {
        It "Contains Source field when Source is provided" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Source "MyFunction" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Source | Should -Be "MyFunction"
        }

        It "Omits Source field when Source is not provided" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.PSObject.Properties.Name | Should -Not -Contain "Source"
        }

        It "Omits Source field when Source is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Source $Value `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.PSObject.Properties.Name | Should -Not -Contain "Source"
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            {
                Write-LogJson `
                    -Level "Invalid" `
                    -Message "A test message" `
                    -Path $script:logFile
            } | Should -Throw
        }

        It "Throws when Path is not provided" {
            {
                Write-LogJson -Level Info -Message "A test message" -Path $null
            } | Should -Throw
        }

        It "Throws when Path is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            {
                Write-LogJson -Level Info -Message "A test message" -Path $Value
            } | Should -Throw
        }
    }

    Context "Rapid sequential writes" {
        It "Preserves all entries across multiple writes" {
            $iterate = 5

            1..$iterate | ForEach-Object {
                Write-LogJson `
                    -Level Info `
                    -Message "A test message" `
                    -Path $script:logFile
            }

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be $iterate
        }

        It "Each entry is valid JSON across multiple writes" {
            $iterate = 5

            1..$iterate | ForEach-Object {
                Write-LogJson `
                    -Level Info `
                    -Message "A test message" `
                    -Path $script:logFile
            }

            Get-Content $script:logFile | ForEach-Object {
                { $_ | ConvertFrom-Json } | Should -Not -Throw
            }
        }
    }
}
