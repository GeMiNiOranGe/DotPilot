<#
Input space
-----------
Param `$Level`:
    [LogLevel] enum. Drives the "Level" field written to the JSON entry. Four
    valid values: Info, Warn, Error, Debug. Each value maps to its string name
    in the serialised output.

Param `$Message`:
    Any string. Written to the "Message" field of the JSON entry. Does not
    affect control flow or Level serialisation. No partitioning needed beyond
    confirming it appears in the output.

Param `$Source`:
    Any string. When non-whitespace, adds a "Source" key to the ordered
    hashtable before serialisation. When absent, $null, or whitespace, the key
    is omitted entirely. $null and whitespace are tested separately as distinct
    representatives of the "effectively absent" partition.

Param `$Path`:
    Mandatory string, ValidateNotNullOrWhiteSpace. Passed directly to
    Add-Content. Does not affect the JSON entry format. No partitioning needed
    beyond confirming Add-Content receives it.

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
Partition    Representative   Expected
---------    --------------   --------
Valid        "Verb-Noun"      JSON contains "Source":"Verb-Noun"
Null         $null            JSON has no "Source" key
Empty        ""               Coerced to "" by PowerShell's [string] binding;
                              same partition as Null, skip
Whitespace   "   "            JSON has no "Source" key

Note: Null and Whitespace are separate representatives of the "effectively
absent" partition and are each tested once.

################################################################################

Decision table
--------------
$Level   $Source      Expected
------   -------      --------
Info     Valid        Compact JSON: Timestamp, Level "Info", Message, Source
Info     Null         Compact JSON: Timestamp, Level "Info", Message, no Source
Info     Whitespace   Compact JSON: no Source key
Warn     Non-Valid    Compact JSON: Level "Warn"
Error    Non-Valid    Compact JSON: Level "Error"
Debug    Non-Valid    Compact JSON: Level "Debug"

Note:
1.  The Timestamp field format is structural and identical across all rows; it
    is verified once on a representative combination rather than repeated on
    every row ('Info + Valid').

2.  The $Path value passed to Add-Content does not vary across $Level or $Source
    combinations; it is asserted once on a representative combination
    ('Info + Valid').

3.  The Message field appears in the output regardless of $Level or $Source. It
    is verified once on a representative combination ('Info + Valid').

4.  The absence of a Source key is asserted once on a representative combination
    ('Info + Null'); presence is asserted on ('Info + Valid').

5.  The JSON is compact (no whitespace between tokens). This structural property
    is verified once on a representative combination ('Info + Valid').

################################################################################

Test map
--------
ID   Context     Input                     TDT   Assert
--   -------     -----                     ---   ------
01   INF + Val   Info, "Server started",   DT    Add-Content called once
                 "Verb-Noun", path
02   INF + Val   ^                         ^     Path arg = test path
03   INF + Val   ^                         ^     Value ~ timestamp pattern
04   INF + Val   ^                         ^     Contains "Level":"Info"
05   INF + Val   ^                         ^     Contains "Message":"..."
06   INF + Val   ^                         ^     Contains "Source":"Verb-Noun"
07   INF + Val   ^                         ^     Value is compact JSON
08   INF + Nul   Info, "Server started",   DT    Value has no "Source" key
                 $null, path
09   INF + WS    Info, "Server started",   DT    Value has no "Source" key
                 "   ", path
10   WRN + Non   Warn, "Disk low", path    DT    Contains "Level":"Warn"
11   ERR + Non   Error, "Disk low", path   DT    Contains "Level":"Error"
12   DBG + Non   Debug, "Disk low", path   DT    Contains "Level":"Debug"

List of Abbreviations:
'^' - Same input/technique as previous row
TDT - Test Design Technique
DT  - Decision Table
INF - Info
WRN - Warn
ERR - Error
DBG - Debug
Nul - Null
Val - Valid
WS  - Whitespace
Non - Non-Valid
#>
Describe "Write-LogJson" -Tag @(
    "Write-LogJson"
    "Write-Log*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Write-LogJson.ps1"

        # Mock Add-Content to avoid actual file I/O and
        # enable verification of parameters.
        Mock Add-Content {}
    }

    Context "When Level is Info and Source is valid" {
        BeforeAll {
            $script:message = "Server started"
            $script:source = "Verb-Noun"
            $script:path = "C:\Logs\log-file.log"

            Write-LogJson `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Source $script:source `
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
        It "Writes an entry that contains the Source value" {
            $format = "*`"Source`":*`"$script:source`"*"

            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like $format }
        }

        # 07
        It "Writes a compact JSON entry with no spaces between tokens" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -notmatch ':\s|,\s' }
        }
    }

    Context "When Level is Info and Source is null" {
        BeforeAll {
            $script:message = "Server started"
            $script:path = "C:\Logs\log-file.log"

            Write-LogJson `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Source $null `
                -Path $script:path
        }

        # 08
        It "Writes an entry that contains no Source key" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -notlike '*"Source":*' }
        }
    }

    Context "When Level is Info and Source is whitespace" {
        BeforeAll {
            $script:message = "Server started"
            $script:path = "C:\Logs\log-file.log"

            Write-LogJson `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Source "   " `
                -Path $script:path
        }

        # 09
        It "Writes an entry that contains no Source key" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -notlike '*"Source":*' }
        }
    }

    Context "When Level is Warn" {
        BeforeAll {
            Write-LogJson `
                -Level ([LogLevel]::Warn) `
                -Message "Disk low" `
                -Path "C:\Logs\log-file.log"
        }

        # 10
        It "Writes an entry with Level 'Warn'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Warn"*' }
        }
    }

    Context "When Level is Error" {
        BeforeAll {
            Write-LogJson `
                -Level ([LogLevel]::Error) `
                -Message "Disk low" `
                -Path "C:\Logs\log-file.log"
        }

        # 11
        It "Writes an entry with Level 'Error'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Error"*' }
        }
    }

    Context "When Level is Debug" {
        BeforeAll {
            Write-LogJson `
                -Level ([LogLevel]::Debug) `
                -Message "Disk low" `
                -Path "C:\Logs\log-file.log"
        }

        # 12
        It "Writes an entry with Level 'Debug'" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like '*"Level":"Debug"*' }
        }
    }
}
