<#
Input space
-----------
Param `$Level`:
    [LogLevel] enum. Drives the level label written to the file. Four valid
    values: Info, Warn, Error, Debug. Each value maps to a distinct uppercase
    label in the entry string.

Param `$Message`:
    Any string. Appended to the entry after the source label. Does not affect
    control flow or label selection. No partitioning needed beyond confirming it
    appears in the output.

Param `$Source`:
    Any string. When non-whitespace, prepends "${Source}: " before $Message.
    When absent, $null, or whitespace, no prefix is written. $null and
    whitespace are tested separately as distinct representatives of the
    "effectively absent" partition.

Param `$Path`:
    String. Passed directly to Add-Content. Does not affect entry format.
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
Partition    Representative   Expected
---------    --------------   --------
Valid        "Verb-Noun"      Entry contains "Verb-Noun: " before $Message
Null         $null            No source prefix in entry
Empty        ""               Coerced to "" by PowerShell's [string] binding;
                              same partition as Empty, skip
Whitespace   "   "            No source prefix in entry

Note: Null and Whitespace are separate representatives of the "effectively
absent" partition and are each tested once.

################################################################################

Decision table
--------------
$Level   $Source      Expected
------   -------      --------
Info     Valid        "<timestamp> INFO\tVerb-Noun: <msg>"
Info     Null         "<timestamp> INFO\t<msg>"
Info     Whitespace   "<timestamp> INFO\t<msg>"
Warn     Non-Valid    "<timestamp> WARN\t<msg>"
Error    Non-Valid    "<timestamp> ERROR\t<msg>"
Debug    Non-Valid    "<timestamp> DEBUG\t<msg>"

Note:
1.  The timestamp prefix format is structural and identical across all rows;
    it is verified once on a representative combination rather than repeated on
    every row ('Info + Null').

2.  The $Path value passed to Add-Content does not vary across $Level or
    $Source combinations; it is asserted once on a representative combination
    ('Info + Null').

3.  The absence of a Source prefix is asserted once on a representative
    combination ('Info + Null'); the presence of a source prefix is asserted
    on ('Info + Valid').

4.  Null and Whitespace Source are each asserted separately as distinct
    representatives of the "effectively absent" partition.

################################################################################

Test map
--------
ID   Context     Input                Technique   Assert
--   -------     -----                ---------   ------
01   INF + Val   Info,                DT          Add-Content called once
                 "Server started",
                 "Verb-Noun", path
02   INF + Val   ^                    ^           Path arg = test path
03   INF + Val   ^                    ^           Entry ~ timestamp pattern
04   INF + Val   ^                    ^           Entry contains "INFO"
05   INF + Val   ^                    ^           Entry contains the message
06   INF + Val   ^                    ^           Entry contains "Verb-Noun: "
07   INF + Nul   Info,                DT          Entry has no source prefix
                 "Server started",
                 $null, path
08   INF + WS    Info,                DT          Entry has no source prefix
                 "Server started",
                 "   ", path
09   WRN + Non   Warn, "Disk low",    DT          Entry contains "WARN"
                 path
10   ERR + Non   Error, "Disk low",   DT          Entry contains "ERROR"
                 path
11   DBG + Non   Debug, "Disk low",   DT          Entry contains "DEBUG"
                 path

List of Abbreviations:
'^' - Same input/technique as previous row
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
Describe "Write-LogFile" -Tag @(
    "Write-LogFile"
    "Write-Log*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Write-LogFile.ps1"

        # Mock Add-Content to avoid actual file I/O and
        # enable verification of parameters.
        Mock Add-Content {}
    }

    Context "When Level is Info and Source is valid" {
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
            $format = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} '

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
        It "Writes an entry that contains the source prefix" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -like "*$script:source`: *" }
        }
    }

    Context "When Level is Info and Source is null" {
        BeforeAll {
            $script:message = "Server started"
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Source $null `
                -Path $script:path
        }

        # 07
        It "Writes an entry with no source prefix before the message" {
            $format = 'INFO\t' + [regex]::Escape($script:message) + '$'

            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match $format }
        }
    }

    Context "When Level is Info and Source is whitespace" {
        BeforeAll {
            $script:message = "Server started"
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -Source "   " `
                -Path $script:path
        }

        # 08
        It "Writes an entry with no source prefix before the message" {
            $format = 'INFO\t' + [regex]::Escape($script:message) + '$'

            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match $format }
        }
    }

    Context "When Level is Warn" {
        BeforeAll {
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Warn) `
                -Message "Disk low" `
                -Path $script:path
        }

        # 09
        It "Writes an entry that contains the WARN label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' WARN\t' }
        }
    }

    Context "When Level is Error" {
        BeforeAll {
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Error) `
                -Message "Disk low" `
                -Path $script:path
        }

        # 10
        It "Writes an entry that contains the ERROR label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' ERROR\t' }
        }
    }

    Context "When Level is Debug" {
        BeforeAll {
            $script:path = "C:\Logs\log-file.log"

            Write-LogFile `
                -Level ([LogLevel]::Debug) `
                -Message "Disk low" `
                -Path $script:path
        }

        # 11
        It "Writes an entry that contains the DEBUG label" {
            Should -Invoke Add-Content -Times 1 -Scope Context `
                -ParameterFilter { $Value -match ' DEBUG\t' }
        }
    }
}
