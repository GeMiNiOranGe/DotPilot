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
