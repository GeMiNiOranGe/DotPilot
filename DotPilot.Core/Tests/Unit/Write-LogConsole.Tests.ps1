<#
Input space
-----------
Param `$Level`:
    [LogLevel] enum. Drives the color map lookup and the label written to the
    console. Four valid values: Info, Warn, Error, Debug. Each value maps to a
    distinct foreground/background color pair and a distinct label string.

Param `$Message`:
    Any string. Appended to the output after the colored label. Does not affect
    control flow or color selection. No partitioning needed beyond confirming
    it appears in the output.

################################################################################

Equivalence Partitioning
------------------------
1. For `$Level`
Partition   Representative      Expected
---------   --------------      --------
Info        [LogLevel]::Info    Write-Host label "info" with Cyan background
Warn        [LogLevel]::Warn    Write-Host label "warn" with Yellow background
Error       [LogLevel]::Error   Write-Host label "error" with Red background
Debug       [LogLevel]::Debug   Write-Host label "debug" with White background

Note: All four partitions are structurally identical (same code path, different
map entry); testing all four validates the full color map.

2. For `$Message`
No partitioning needed. $Message does not affect control flow or color
selection. A single representative value is sufficient to confirm it is passed
through to the second Write-Host call.

################################################################################

Decision table
--------------
$Level   $Message   Expected
------   --------   --------
Info     Any        Write-Host "info" w/ Black/Cyan; Write-Host " $Message"
Warn     Any        Write-Host "warn" w/ Black/Yellow; Write-Host " $Message"
Error    Any        Write-Host "error" w/ Black/Red; Write-Host " $Message"
Debug    Any        Write-Host "debug" w/ Black/White; Write-Host " $Message"

Note:
1.  $Message does not affect the color or label output. The second Write-Host
    call (message line) is only verified once against a representative $Level
    to avoid redundant assertions ('Info + Any').

2.  ForegroundColor (Black) is constant across all $Level values. It is tested
    once on the Info partition as a representative and omitted from Warn, Error,
    and Debug to avoid repetition ('Info + Any').

################################################################################

Test map
--------
ID   Context   Input                    TDT   Assert
--   -------   -----                    ---   ------
01   Info      Info, "Server started"   EP    Label BGC = Cyan
02   Info      ^                        ^     Label FGC = Black
03   Info      ^                        ^     Label Object = "info"
04   Info      ^                        ^     Label NoNewline = true
05   Info      ^                        ^     Message = " Server started"
06   Warn      Warn, "Disk low"         EP    Label BGC = Yellow
07   Warn      ^                        ^     Label Object = "warn"
08   Error     Error, "Disk low"        EP    Label BGC = Red
09   Error     ^                        ^     Label Object = "error"
10   Debug     Debug, "Disk low"        EP    Label BGC = White
11   Debug     ^                        ^     Label Object = "debug"

List of Abbreviations:
'^' - Same capture as previous assertion(s)
TDT - Test Design Technique
EP  - Equivalence Partitioning
BGC - BackgroundColor
FGC - ForegroundColor
#>
Describe "Write-LogConsole" -Tag @(
    "Write-LogConsole"
    "Write-Log*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Write-LogConsole.ps1"

        Mock Write-Host {}
    }

    Context "When Level is Info" {
        BeforeAll {
            $script:message = "Server started"

            Write-LogConsole -Level ([LogLevel]::Info) -Message $script:message
        }

        # 01
        It "Writes the label with Cyan background" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $BackgroundColor -eq [ConsoleColor]::Cyan
            }
        }

        # 02
        It "Writes the label with Black foreground" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $ForegroundColor -eq [ConsoleColor]::Black
            }
        }

        # 03
        It "Writes 'info' as the label text" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $Object -eq "info"
            }
        }

        # 04
        It "Writes the label without a trailing newline" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $NoNewline -eq $true
            }
        }

        # 05
        It "Writes the message with a leading space" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $Object -eq " $script:message"
            }
        }
    }

    Context "When Level is Warn" {
        BeforeAll {
            Write-LogConsole -Level ([LogLevel]::Warn) -Message "Disk low"
        }

        # 06
        It "Writes the label with Yellow background" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $BackgroundColor -eq [ConsoleColor]::Yellow
            }
        }

        # 07
        It "Writes 'warn' as the label text" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $Object -eq "warn"
            }
        }
    }

    Context "When Level is Error" {
        BeforeAll {
            Write-LogConsole -Level ([LogLevel]::Error) -Message "Disk low"
        }

        # 08
        It "Writes the label with Red background" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $BackgroundColor -eq [ConsoleColor]::Red
            }
        }

        # 09
        It "Writes 'error' as the label text" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $Object -eq "error"
            }
        }
    }

    Context "When Level is Debug" {
        BeforeAll {
            Write-LogConsole -Level ([LogLevel]::Debug) -Message "Disk low"
        }

        # 10
        It "Writes the label with White background" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $BackgroundColor -eq [ConsoleColor]::White
            }
        }

        # 11
        It "Writes 'debug' as the label text" {
            Should -Invoke Write-Host -Times 1 -Scope Context -ParameterFilter {
                $Object -eq "debug"
            }
        }
    }
}
