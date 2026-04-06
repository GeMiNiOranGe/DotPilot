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
Describe "Write-LogFile" -Tag @(
    "Write-LogFile"
    "Write-Log*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogFile.ps1"

        Mock Get-Date {
            return "2000-01-01 12:00:00"
        }

        # Mock Add-Content to avoid actual file I/O and
        # enable verification of parameters.
        Mock Add-Content {}
    }

    Context "When Level is Info and Source is absent" {
        BeforeAll {
            $script:message = "Server started"
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Path $script:path
        }

        # 01
        It "Calls Add-Content exactly once" {
            Should -Invoke Add-Content -Times 1 -Scope Context
        }

        # 02
        It "Passes the correct path to Add-Content" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Path -eq $script:path }
        }

        # 03
        It "Writes an entry that begins with a formatted timestamp" {
            $format = '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} '

            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match $format }
        }

        # 04
        It "Writes an entry that contains the INFO label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' INFO\t' }
        }

        # 05
        It "Writes an entry that contains the message" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like "*$script:message" }
        }

        # 06
        It "Writes an entry with no source prefix before the message" {
            $format = 'INFO\t' + [regex]::Escape($script:message) + '$'

            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match $format }
        }
    }

    Context "When Level is Info and Source is present" {
        BeforeAll {
            $script:message = "Server started"
            $script:source = "Verb-Noun"
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Source $script:source `
                -Path $script:path
        }

        # 07
        It "Writes an entry that contains the source prefix" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like "*$script:source`: *" }
        }
    }

    Context "When Level is Warn and Source is absent" {
        BeforeAll {
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Warn) `
                -Message "Disk low" `
                -Path $script:path
        }

        # 08
        It "Writes an entry that contains the WARN label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' WARN\t' }
        }
    }

    Context "When Level is Error and Source is absent" {
        BeforeAll {
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Error) `
                -Message "Disk low" `
                -Path $script:path
        }

        # 09
        It "Writes an entry that contains the ERROR label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' ERROR\t' }
        }
    }

    Context "When Level is Debug and Source is absent" {
        BeforeAll {
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Debug) `
                -Message "Disk low" `
                -Path $script:path
        }

        # 10
        It "Writes an entry that contains the DEBUG label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' DEBUG\t' }
        }
    }
}
