<#
Input space
-----------
Param `$Level`:
    [LogLevel] enum. Passed through to Write-LogConsole and, when file logging
    is enabled, embedded in the file entry by Write-LogFile / Write-LogJson.
    Four valid values: Info, Warn, Error, Debug. Does not affect control flow
    inside Write-Log itself.

Param `$Message`:
    Any string. Passed through to Write-LogConsole and, when file logging is
    enabled, embedded in the file entry. Does not affect control flow.
    No partitioning needed.

Param `$Source`:
    Pass-through parameter. Forwarded unchanged to Write-LogFile /
    Write-LogJson. Correct rendering in the file entry is covered by the
    unit tests of those functions. Not tested here.

Param `$FileName`:
    Any string. Required when file logging is enabled. When blank/absent and
    file logging is on, a terminating error is thrown. When file logging is off,
    ignored entirely.

Param `$OutputDirectory`:
    Any string. When non-empty and file logging is enabled, the file is written
    under that directory. When empty / absent, the file is written relative to
    the current location. When file logging is off, ignored entirely.

Global state
------------
$global:DotPilot.Log.FileLogging: Boolean. Primary branch condition.
    $false -> console-only path.
    $true  -> file-logging path.

$global:DotPilot.Log.FileFormat : String / [LogFormat] enum.
    "Log"  -> .log file written by Write-LogFile.
    "Json" -> .jsonl file written by Write-LogJson.
    "None" -> LogFormatNotSet error thrown.
    Unparseable -> InvalidLogFormat error thrown.

################################################################################

Equivalence Partitioning
------------------------
1. For `$global:DotPilot.Log.FileLogging`
Partition   Representative   Expected
---------   --------------   --------
Disabled    $false           No file created; Write-Host called (console)
Enabled     $true            File-logging branch executed

2. For `$FileName` (relevant only when FileLogging = $true)
Partition   Representative   Expected
---------   --------------   --------
Absent      ""               Terminating error thrown; no file created
Present     "run"            Proceeds; file created

3. For `$OutputDirectory` (relevant only when FileLogging = $true,
   FileName Present)
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           File created as "$FileName.$ext" in current dir
Present     $TestDrive       File created as "$TestDrive\$FileName.$ext"

4. For `$global:DotPilot.Log.FileFormat` (relevant only when
   FileLogging = $true, FileName Present)
Partition     Representative   Expected
---------     --------------   --------
Log           "Log"            .log file created; entry in plain-text format
Json          "Json"           .jsonl file created; entry in JSON format
None          "None"           LogFormatNotSet error thrown; no file created
Unparseable   "???"            InvalidLogFormat error thrown; no file created

################################################################################

Decision table
--------------
FL    FileName   OutDir    Format   Expected
--    --------   ------    ------   --------
Off   Any        Any       Any      No file created; Write-Host called
On    Absent     Any       Any      Terminating error thrown
On    Present    Absent    Log      run.log created in current dir;
                                    entry contains Level + Message
On    Present    Present   Log      run.log created under OutputDir
On    Present    Absent    Json     run.jsonl created in current dir;
                                    entry is valid JSON with Level + Message
On    Present    Absent    None     LogFormatNotSet error; no file created
On    Present    Absent    Bad      InvalidLogFormat error; no file created

Note:
1.  Write-Host (console output) is always triggered regardless of the
    file-logging path. It is verified once on a representative combination
    to avoid redundant assertions ('FL Off + Any').

2.  $Level and $Message appear in the file entry on every file-logging row.
    Full entry-content assertions (Level label, Message text) are done once
    on the representative combination ('FL On + Present + Absent + Log').
    Remaining file-logging rows only assert file existence / format shape
    to avoid repetition.

3.  The error rows (None and Bad format) terminate before any file is written
    and before Write-Host is reached, so no file-existence or console assertion
    is made for those combinations.

4.  The OutputDirectory-present row ('FL On + Present + Present + Log') focuses
    on path placement. Entry-content assertions are omitted there; they are
    already covered by ('FL On + Present + Absent + Log').

################################################################################

Test map
--------
ID   Context   Input                 Technique   Assert
--   -------   -----                 ---------   ------
01   FL Off    Info, "msg",          DT          No file created
               FL=$false
02   ^         ^                     ^           Write-Host called
03   FL On,    Info, "msg",          DT          Throws ArgumentBlankException
     FN Abs    FL=$true, FN=""
04   FL On,    Info, "Server         DT          run.log exists
     FN Pre,   started",
     OD Abs,   FL=$true, FN="run",
     Log       OD="", Fmt=Log
05   ^         ^                     ^           Entry ~ timestamp pattern
06   ^         ^                     ^           Entry contains "INFO" label
07   ^         ^                     ^           Entry contains Message
08   ^         ^                     ^           Write-Host called
09   FL On,    Info, "msg",          DT          run.log exists under OutputDir
     FN Pre,   FL=$true, FN="run",
     OD Pre,   OD=$TestDrive,
     Log       Fmt=Log
10   FL On,    Info, "msg",          DT          run.jsonl exists
     FN Pre,   FL=$true, FN="run",
     OD Abs,   OD="", Fmt=Json
     Json
11   ^         ^                     ^           Entry is valid JSON
12   ^         ^                     ^           JSON Level = "Info"
13   ^         ^                     ^           JSON Message = "msg"
14   FL On,    Info, "msg",          DT          ErrorId = LogFormatNotSet
     FN Pre,   FL=$true, FN="run",
     OD Abs,   OD="", Fmt=None
     None
15   FL On,    Info, "msg",          DT          ErrorId = InvalidLogFormat
     FN Pre,   FL=$true, FN="run",
     OD Abs,   OD="", Fmt="???"
     Bad

List of Abbreviations:
'^'  - Same context/input/technique as previous row
DT   - Decision Table
FL   - FileLogging ($global:DotPilot.Log.FileLogging)
FN   - FileName
OD   - OutputDirectory
Abs  - Absent (empty string or omitted)
Pre  - Present (non-empty value)
Fmt  - FileFormat ($global:DotPilot.Log.FileFormat)
Log  - [LogFormat]::Log
Json - [LogFormat]::Json
Bad  - Unparseable format string
#>
Describe "Write-Log" -Tag "Write-Log", "Write-Log*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogFormat.ps1"
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogConsole.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogFile.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogJson.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-DirectoryExists.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-ArgumentExists.ps1"
        . "$PSScriptRoot\..\Src\Public\Write-Log.ps1"

        Mock Write-LogConsole {}
        Mock Write-LogFile {}
        Mock Write-LogJson {}
        Mock Assert-DirectoryExists {}
        Mock Assert-ArgumentExists {}
    }

    BeforeEach {
        $script:fileName = "test"
        $script:outputDir = $TestDrive

        $global:DotPilot = @{
            Log = @{
                FileLogging = $false
                FileFormat  = "Log"
            }
        }
    }

    Context "Console logging" {
        It "Calls Write-LogConsole when file logging is disabled" {
            Write-Log -Level Info -Message "A test message"
            Should -Invoke Write-LogConsole -Times 1 -Exactly
        }

        It "Calls Write-LogConsole even when file logging is enabled" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogConsole -Times 1 -Exactly
        }

        It "Passes correct parameters to Write-LogConsole" {
            Write-Log -Level Error -Message "A test message"

            Should -Invoke Write-LogConsole -ParameterFilter {
                $Level -eq "Error" -and
                $Message -eq "A test message"
            }
        }
    }

    Context "File logging" {
        It "Does not call Write-LogFile when file logging is disabled" {
            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogFile -Times 0
        }

        It "Calls Write-LogFile when file logging is enabled" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogFile -Times 1 -Exactly
        }

        It "Passes correct parameters to Write-LogFile with -OutputDirectory" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Error `
                -Message "A test message" `
                -Source "MyFunction" `
                -FileName $script:fileName `
                -OutputDirectory $script:outputDir

            Should -Invoke Write-LogFile -ParameterFilter {
                $Level -eq "Error" -and
                $Message -eq "A test message" -and
                $Source -eq "MyFunction" -and
                $Path -eq (Join-Path $script:outputDir "$script:fileName.log")
            }
        }

        It "Resolves path to current directory when -OutputDirectory is not provided" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogFile -ParameterFilter {
                $Path -eq "$script:fileName.log"
            }
        }

        It "Passes empty Source to Write-LogFile when -Source is not provided" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogFile -ParameterFilter {
                [string]::IsNullOrEmpty($Source)
            }
        }

        It "Calls Write-LogJson when FileFormat is Json" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "Json"

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogJson -Times 1 -Exactly
        }

        It "Does not call Write-LogFile when FileFormat is Json" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "Json"

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogFile -Times 0
        }

        It "Passes correct parameters to Write-LogJson with -OutputDirectory" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "Json"

            Write-Log `
                -Level Error `
                -Message "A test message" `
                -Source "MyFunction" `
                -FileName $script:fileName `
                -OutputDirectory $script:outputDir

            Should -Invoke Write-LogJson -ParameterFilter {
                $Level -eq "Error" -and
                $Message -eq "A test message" -and
                $Source -eq "MyFunction" -and
                $Path -eq (Join-Path $script:outputDir "$script:fileName.jsonl")
            }
        }

        It "Resolves path to current directory when -OutputDirectory is not provided (Json)" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "Json"

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogJson -ParameterFilter {
                $Path -eq "$script:fileName.jsonl"
            }
        }

        It "Passes empty Source to Write-LogJson when -Source is not provided" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "Json"

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Write-LogJson -ParameterFilter {
                [string]::IsNullOrEmpty($Source)
            }
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            {
                Write-Log -Level "Invalid" -Message "A test message"
            } | Should -Throw
        }

        It "Calls Assert-ArgumentExists for -FileName when file logging is enabled" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log -Level Info -Message "A test message"

            Should -Invoke Assert-ArgumentExists -Times 1 -Exactly -ParameterFilter {
                $Name -eq "FileName" -and
                [string]::IsNullOrEmpty($Value)
            }
        }

        It "Throws when FileFormat is unsupported" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "Unsupported"

            {
                Write-Log `
                    -Level Info `
                    -Message "A test message" `
                    -FileName $script:fileName

            } | Should -Throw "*Invalid log file format value*"
        }

        It "Calls Assert-DirectoryExists when file logging is enabled and -OutputDirectory is provided" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName `
                -OutputDirectory $script:outputDir

            Should -Invoke Assert-DirectoryExists -Times 1 -Exactly -ParameterFilter {
                $Path -eq $script:outputDir
            }
        }

        It "Does not call Assert-DirectoryExists when -OutputDirectory is not provided" {
            $global:DotPilot.Log.FileLogging = $true

            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName

            Should -Invoke Assert-DirectoryExists -Times 0
        }

        It "Does not call Assert-DirectoryExists when file logging is disabled" {
            Write-Log `
                -Level Info `
                -Message "A test message" `
                -FileName $script:fileName `
                -OutputDirectory $script:outputDir

            Should -Invoke Assert-DirectoryExists -Times 0
        }

        It "Throws when FileFormat is None" {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "None"

            {
                Write-Log `
                    -Level Info `
                    -Message "A test message" `
                    -FileName $script:fileName
            } | Should -Throw
        }
    }
}
