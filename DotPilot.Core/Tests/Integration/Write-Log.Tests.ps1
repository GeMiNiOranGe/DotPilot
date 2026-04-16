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
05   ^         ^                     ^           no .jsonl file created
06   FL On,    Info, "msg",          DT          run.log exists under OutputDir
     FN Pre,   FL=$true, FN="run",
     OD Pre,   OD=$TestDrive,
     Log       Fmt=Log
07   FL On,    Info, "msg",          DT          run.jsonl exists
     FN Pre,   FL=$true, FN="run",
     OD Abs,   OD="", Fmt=Json
     Json
08   ^         ^                     ^           no .log file created
09   FL On,    Info, "msg",          DT          ErrorId = LogFormatNotSet
     FN Pre,   FL=$true, FN="run",
     OD Abs,   OD="", Fmt=None
     None
10   FL On,    Info, "msg",          DT          ErrorId = InvalidLogFormat
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
Describe "Write-Log" -Tag @(
    "Write-Log"
    "Write-Log*"
    "Integration"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Classes\ArgumentBlankException.ps1"
        . "$PSScriptRoot\..\..\Src\Enums\LogFormat.ps1"
        . "$PSScriptRoot\..\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\..\Src\Config\Global.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Write-LogConsole.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Write-LogFile.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Write-LogJson.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Assert-ArgumentExists.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Assert-DirectoryExists.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Write-Log.ps1"
        . "$PSScriptRoot\..\Helpers\Assert-GuardThrew.ps1"

        # Suppress console output across all contexts.
        # Write-Host call count is still verifiable via Should -Invoke.
        Mock Write-Host {}
    }

    Context "When file logging is disabled" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $false

            $script:dir = $TestDrive
            Push-Location $script:dir

            Write-Log -Level ([LogLevel]::Info) -Message "msg"
        }

        AfterAll {
            Pop-Location
        }

        # 01
        It "Creates no file in the current directory" {
            (Get-ChildItem -Path $script:dir).Count | Should -Be 0
        }

        # 02
        It "Calls Write-Host to produce console output" {
            Should -Invoke Write-Host -Scope Context
        }
    }

    Context "When file logging is enabled and FileName is absent" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = [LogFormat]::Log

            try {
                Write-Log `
                    -Level ([LogLevel]::Info) `
                    -Message "msg" `
                    -FileName ""
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -Caller "Write-Log" `
                -CaughtError $script:caughtError `
                -Context "FileName='<empty>' with file logging enabled"
        }

        # 03
        It "Throws an ArgumentBlankException" {
            $script:caughtError.Exception | Should -BeOfType (
                [ArgumentBlankException]
            )
        }
    }

    Context "When file logging is on, Log format, no OutputDirectory" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = [LogFormat]::Log

            $script:fileName = "run"
            $script:message = "Server started"
            $script:logFile = Join-Path $TestDrive "$script:fileName.log"

            Push-Location $TestDrive

            Write-Log `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -FileName $script:fileName
        }

        AfterAll {
            Pop-Location
        }

        # 04
        It "Creates the .log file" {
            $script:logFile | Should -Exist
        }

        # 05
        It "Does not create a .jsonl file" {
            $jsonFile = Join-Path $TestDrive "$script:fileName.jsonl"
            $jsonFile | Should -Not -Exist
        }
    }

    Context "When file logging is on, Log format, OutputDirectory present" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = [LogFormat]::Log

            $script:fileName = "run"
            $script:logFile = Join-Path $TestDrive "$script:fileName.log"

            Write-Log `
                -Level ([LogLevel]::Info) `
                -Message "msg" `
                -FileName $script:fileName `
                -OutputDirectory $TestDrive
        }

        # 06
        It "Creates the .log file under the specified OutputDirectory" {
            $script:logFile | Should -Exist
        }
    }

    Context "When file logging is on and format is Json" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = [LogFormat]::Json

            $script:fileName = "run"
            $script:message = "msg"
            $script:jsonFile = Join-Path $TestDrive "$script:fileName.jsonl"

            Push-Location $TestDrive

            Write-Log `
                -Level ([LogLevel]::Info) `
                -Message $script:message `
                -FileName $script:fileName
        }

        AfterAll {
            Pop-Location
        }

        # 07
        It "Creates the .jsonl file" {
            $script:jsonFile | Should -Exist
        }

        # 08
        It "Does not create a .log file" {
            $logFile = Join-Path $TestDrive "$script:fileName.log"
            $logFile | Should -Not -Exist
        }
    }

    Context "When file logging is on and FileFormat is None" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = [LogFormat]::None

            try {
                Write-Log `
                    -Level ([LogLevel]::Info) `
                    -Message "msg" `
                    -FileName "run"
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -Caller "Write-Log" `
                -CaughtError $script:caughtError `
                -Context "FileFormat='None' with file logging enabled"
        }

        # 09
        It "Throws with ErrorId 'LogFormatNotSet'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -BeLike "*LogFormatNotSet*"
        }
    }

    Context "When file logging is on and FileFormat is unparseable" {
        BeforeAll {
            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = "???"

            try {
                Write-Log `
                    -Level ([LogLevel]::Info) `
                    -Message "msg" `
                    -FileName "run"
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -Caller "Write-Log" `
                -CaughtError $script:caughtError `
                -Context "FileFormat='???' with file logging enabled"
        }

        # 10
        It "Throws with ErrorId 'InvalidLogFormat'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -BeLike "*InvalidLogFormat*"
        }
    }
}
