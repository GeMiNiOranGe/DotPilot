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
Describe "Write-LogJson" -Tag @(
    "Write-LogJson"
    "Write-Log*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogJson.ps1"

        Mock Get-Date {
            return "2000-01-01T12:00:00"
        }

        # Mock Add-Content to avoid actual file I/O and
        # enable verification of parameters.
        Mock Add-Content {}
    }

    Context "When Level is Info and Source is absent" {
        BeforeAll {
            $script:message = "Server started"
            $script:path = "C:\Logs\log-file.log"

            Write-LogJson `
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
        It "Writes an entry whose Timestamp matches the ISO-8601 pattern" {
            $format = '"Timestamp":"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"'

            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match $format }
        }

        # 04
        It "Writes an entry with Level 'Info'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Info"*' }
        }

        # 05
        It "Writes an entry with the correct Message value" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter {
                    $Value -like "*`"Message`":*`"$script:message`"*"
                }
        }

        # 06
        It "Writes an entry that contains no Source key" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -notlike '*"Source":*' }
        }

        # 07
        It "Writes a compact JSON entry with no spaces between tokens" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -notmatch ':\s|,\s' }
        }
    }

    Context "When Level is Info and Source is present" {
        BeforeAll {
            $script:source = "Verb-Noun"

            Write-LogJson `
                -Level ([LogLevel]::Info) `
                -Message "Server started" `
                -Source $script:source `
                -Path "C:\Logs\log-file.log"
        }

        # 08
        It "Writes an entry that contains the Source value" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter {
                    $Value -like "*`"Source`":*`"$script:source`"*"
                }
        }
    }

    Context "When Level is Warn and Source is absent" {
        BeforeAll {
            Write-LogJson `
                -Level ([LogLevel]::Warn) `
                -Message "Disk low" `
                -Path "C:\Logs\log-file.log"
        }

        # 09
        It "Writes an entry with Level 'Warn'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Warn"*' }
        }
    }

    Context "When Level is Error and Source is absent" {
        BeforeAll {
            Write-LogJson `
                -Level ([LogLevel]::Error) `
                -Message "Disk low" `
                -Path "C:\Logs\log-file.log"
        }

        # 10
        It "Writes an entry with Level 'Error'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Error"*' }
        }
    }

    Context "When Level is Debug and Source is absent" {
        BeforeAll {
            Write-LogJson `
                -Level ([LogLevel]::Debug) `
                -Message "Disk low" `
                -Path "C:\Logs\log-file.log"
        }

        # 11
        It "Writes an entry with Level 'Debug'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Debug"*' }
        }
    }
}
