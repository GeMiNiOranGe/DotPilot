<#
Input space
-----------
$Level  : [LogLevel] enum. Drives the level label written to the file. Four
          valid values: Info, Warn, Error, Debug. Each value maps to a distinct
          uppercase label in the entry string.
$Message: Any string. Appended to the entry after the source label. Does not
          affect control flow or label selection. No partitioning needed beyond
          confirming it appears in the output.
$Source : Any string. When non-whitespace, prepends "${Source}: " before
          $Message. When Absent or whitespace, no prefix is written. $null is
          coerced to empty string by IsNullOrWhiteSpace - same partition as
          Absent; no duplicate row needed.
$Path   : String. Passed directly to Add-Content. Does not affect entry format.
          No partitioning needed beyond confirming Add-Content receives it.

################################################################################

Equivalence Partitioning
------------------------
1. For `$Level`
Partition   Representative      Expected
---------   --------------      --------
Info        [LogLevel]::Info    "INFO"
Warn        [LogLevel]::Warn    "WARN"
Error       [LogLevel]::Error   "ERROR"
Debug       [LogLevel]::Debug   "DEBUG"

Note: All four partitions follow the same code path (ToUpper on the enum name);
testing all four validates the full label map.

2. For `$Source`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           No source prefix in entry
Present     "Verb-Noun"      Entry contains "Verb-Noun: " before $Message

################################################################################

Decision table
--------------
$Level   $Source   Expected
------   -------   --------
Info     Absent    "<timestamp> INFO\t<msg>"
Info     Present   "<timestamp> INFO\tVerb-Noun: <msg>"
Warn     Absent    "<timestamp> WARN\t<msg>"
Error    Absent    "<timestamp> ERROR\t<msg>"
Debug    Absent    "<timestamp> DEBUG\t<msg>"

Note:
1.  The timestamp prefix format is structural and identical across all rows;
    it is verified once on a representative combination rather than repeated on
    every row ('Info + Absent').

2.  The $Path value passed to Add-Content does not vary across $Level or
    $Source combinations; it is asserted once on a representative combination
    ('Info + Absent').

3.  The absence of a source prefix is asserted once on a representative
    combination ('Info + Absent'); the presence of a source prefix is asserted
    on ('Info + Present').

################################################################################

Test map
--------
ID   Context     Input                Technique   Assert
--   -------     -----                ---------   ------
01   INF + Abs   Info,                DT          Add-Content called once
                 "Server started",
                 path
02   INF + Abs   ^                    ^           Path arg = test path
03   INF + Abs   ^                    ^           Entry ~ timestamp pattern
04   INF + Abs   ^                    ^           Entry contains "INFO"
05   INF + Abs   ^                    ^           Message = " Server started"
06   INF + Abs   ^                    ^           Entry has no source prefix
07   INF + Pre   Info,                DT          Entry contains "Verb-Noun: "
                 "Server started",
                 "Verb-Noun", path
08   WRN + Abs   Warn, "Disk low",    DT          Entry contains "WARN"
                 path
09   ERR + Abs   Error, "Disk low",   DT          Entry contains "ERROR"
                 path
10   DBG + Abs   Debug, "Disk low",   DT          Entry contains "DEBUG"
                 path

List of Abbreviations:
'^' - Same input/technique as previous row
DT  - Decision Table
INF - Info
WRN - Warn
ERR - Error
DBG - Debug
S   - Source
Abs - Absent
Pre - Present
#>
Describe "Write-LogFile" -Tag "Write-LogFile", "Write-Log*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogFile.ps1"

        Mock Get-Date {
            return "2000-01-01 12:00:00"
        }

        function Get-FirstLogLine {
            param([string]$Path)
            return Get-Content $Path | Select-Object -First 1
        }
    }

    BeforeEach {
        $script:logFile = Join-Path $TestDrive "test.log"
    }

    AfterEach {
        if ($script:logFile -and (Test-Path $script:logFile)) {
            Remove-Item $script:logFile
        }
    }

    Context "File handling" {
        It "Creates log file when it does not exist" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $script:logFile | Should -Exist
        }

        It "Appends entries to existing log file" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 2
        }
    }

    Context "Log entry format" {
        It "Has timestamp prefix" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} '
        }

        It "Contains the message" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match 'A test message$'
        }

        It "Contains level '<Level>' in uppercase" -TestCases @(
            @{ Level = "Info"; Expected = "INFO" }
            @{ Level = "Warn"; Expected = "WARN" }
            @{ Level = "Error"; Expected = "ERROR" }
            @{ Level = "Debug"; Expected = "DEBUG" }
        ) {
            Write-LogFile `
                -Level $Level `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match " $Expected`t"
        }

        It "Has correct full format without Source" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} INFO\tA test message$'
        }

        It "Has correct full format with Source" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Source "MyFunction" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} INFO\tMyFunction: A test message$'
        }
    }

    Context "Source label" {
        It "Contains source label when Source is provided" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile `
                -Source "MyFunction"

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match " INFO`tMyFunction: A test message$"
        }

        It "Omits source label when Source is not provided" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match " INFO`tA test message$"
        }

        It "Does not include source label when Source is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Source $Value `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match " INFO`tA test message$"
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            {
                Write-LogFile `
                    -Level "Invalid" `
                    -Message "A test message" `
                    -Path $script:logFile
            } | Should -Throw
        }

        It "Throws when Path is not provided" {
            {
                Write-LogFile -Level Info -Message "A test message" -Path $null
            } | Should -Throw
        }

        It "Throws when Path is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            {
                Write-LogFile -Level Info -Message "A test message" -Path $Value
            } | Should -Throw
        }
    }

    Context "Rapid sequential writes" {
        It "Preserves all entries across multiple writes" {
            $iterate = 5

            1..$iterate | ForEach-Object {
                Write-LogFile `
                    -Level Info `
                    -Message "A test message" `
                    -Path $script:logFile
            }

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be $iterate
        }
    }
}
