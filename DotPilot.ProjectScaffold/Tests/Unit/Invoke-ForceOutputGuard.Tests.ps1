<#
Input space
-----------
Param `$Path`:
    Any string representing a file path. On the Force path, drives whether
    a parent directory is created. On the non-Force path, forwarded to
    Assert-ParentDirectoryExists and Assert-FileNotExists.

Param `$Cmdlet`:
    Fixed to $PSCmdlet of the synthetic wrapper in all tests. No partitioning
    needed.

Param `$Force`:
    [switch]. Primary branch condition.
    Present -> Force path: create parent dir if missing, skip guards.
    Absent  -> Guard path: run Assert-ParentDirectoryExists then
               Assert-FileNotExists.

################################################################################

Equivalence Partitioning
------------------------
1. For `$Force`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           Guard path: Assert-ParentDirectoryExists
                             and Assert-FileNotExists are invoked
Present     -Force           Force path: New-Item called if parent missing;
                             guards are not invoked

2. For `$Path` on the Force path
(Only the parent-directory condition matters here)

Partition        Representative          Expected
---------        --------------          --------
No parent        "file.txt"              No New-Item call; no throw
Parent exists    "<existing>\file.txt"   No New-Item call; no throw
Parent missing   "<missing>\file.txt"    New-Item -ItemType Directory called

3. For `$Path` on the Guard path
Behavior is entirely delegated to Assert-ParentDirectoryExists and
Assert-FileNotExists. Whether those guards throw is determined by their own
logic, verified via Should -Invoke wiring only. No additional path partitions
are needed beyond confirming both functions are called.

################################################################################

Decision table
--------------
$Force    $Path            Expected
------    -----            --------
Absent    Any              Assert-ParentDirectoryExists invoked;
                           Assert-FileNotExists invoked
Present   No parent        No New-Item call
Present   Parent exists    No New-Item call
Present   Parent missing   New-Item -ItemType Directory called;
                           Assert-* not invoked

Note:
1.  On the Guard path ($Force absent), $Path is "Any" because
    Invoke-ForceOutputGuard performs no branching on it - it is
    forwarded verbatim. Wiring is verified once on a representative
    value ('Force Absent + Any').

2.  New-Item is never called on 'Force Absent' combinations.
    Assert-ParentDirectoryExists and Assert-FileNotExists are never called on
    'Force Present' combinations. These mutual exclusions are verified on
    the representative rows only.

3.  'Force Present + No parent' and 'Force Present + Parent exists' share
    the same observable outcome (no New-Item call). Each maps to its own Context
    per the 1-row-per-Context rule.

################################################################################

Test map
--------
ID   Context    Input                  Technique   Assert
--   -------    -----                  ---------   ------
01   FA + Any   "file.txt", no Force   DT          Assert-ParentDirectoryExists
                                                   invoked
02   ^          ^                      ^           Assert-FileNotExists invoked
03   FP + NP    "file.txt", -Force     DT          No New-Item call
04   FP + PE    "<existing>\f.txt",    DT          No New-Item call
                -Force
05   FP + PM    "<missing>\f.txt",     DT          New-Item invoked with
                -Force                             -ItemType Directory

List of Abbreviations:
'^' - Same context/input/technique as previous row
DT  - Decision Table
FA  - Force Absent
FP  - Force Present
NP  - No Parent in path
PE  - Parent Exists on disk
PM  - Parent Missing from disk
#>
Describe "Invoke-ForceOutputGuard" -Tag @(
    "Invoke-ForceOutputGuard"
    "Invoke-*"
    "Unit"
) {
    BeforeAll {
        $coreModule = "$PSScriptRoot\..\..\..\DotPilot.Core"

        . "$coreModule\Src\Public\Assert-ParentDirectoryExists.ps1"
        . "$coreModule\Src\Public\Assert-FileNotExists.ps1"
        . "$PSScriptRoot\..\..\Src\Private\Invoke-ForceOutputGuard.ps1"

        Mock Assert-ParentDirectoryExists {}
        Mock Assert-FileNotExists {}
        Mock New-Item {}

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Path,
                [switch]$Force
            )
            Invoke-ForceOutputGuard `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -Force:$Force
        }
    }

    Context "When Force is absent" {
        BeforeAll {
            $script:path = "file.txt"

            Invoke-Caller -Path $script:path
        }

        # 01
        It "Invokes Assert-ParentDirectoryExists" {
            Should -Invoke Assert-ParentDirectoryExists `
                -Scope Context `
                -Times 1 `
                -ParameterFilter { $Path -eq $script:path }
        }

        # 02
        It "Invokes Assert-FileNotExists" {
            Should -Invoke Assert-FileNotExists `
                -Scope Context `
                -Times 1 `
                -ParameterFilter { $Path -eq $script:path }
        }
    }

    Context "When Force is present and path has no parent" {
        BeforeAll {
            # A bare filename has no directory component. GetDirectoryName
            # returns "" -> condition is false -> no New-Item call.
            Invoke-Caller -Path "file.txt" -Force
        }

        # 03
        It "Does not call New-Item" {
            Should -Not -Invoke New-Item -Scope Context
        }
    }

    Context "When Force is present and parent directory exists" {
        BeforeAll {
            $parent = Join-Path $TestDrive "existing_parent"
            [void][System.IO.Directory]::CreateDirectory($parent)
            $script:filePath = Join-Path $parent "file.txt"

            Invoke-Caller -Path $script:filePath -Force
        }

        # 04
        It "Does not call New-Item" {
            Should -Not -Invoke New-Item -Scope Context
        }
    }

    Context "When Force is present and parent directory is missing" {
        BeforeAll {
            $missingParent = Join-Path $TestDrive "missing_parent"
            $script:filePath = Join-Path $missingParent "file.txt"

            Invoke-Caller -Path $script:filePath -Force
        }

        # 05
        It "Calls New-Item with -ItemType Directory" {
            Should -Invoke New-Item `
                -Scope Context `
                -Times 1 `
                -ParameterFilter { $ItemType -eq "Directory" }
        }
    }
}
