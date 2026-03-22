Describe "Assert-ParameterExists" -Tag "Assert-ParameterExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Assert-ParameterExists.ps1"

        # Minimal advanced function to capture $PSCmdlet from a real caller context
        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Name,
                [AllowEmptyString()]
                [string]$Value,
                [string]$ExtraMessage
            )
            Assert-ParameterExists `
                -Name $Name `
                -Value $Value `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When parameter value is provided" {
        It "Does not throw when parameter value is not empty" {
            {
                Invoke-Caller -Name "Environment" -Value "staging"
            } | Should -Not -Throw
        }
    }

    Context "When parameter value is null or empty" {
        BeforeEach {
            $script:name = "Environment"
        }

        It "Throws ArgumentException when parameter value is empty" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ExceptionType ([System.ArgumentException])
        }

        It "Error message contains the parameter name" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ExpectedMessage "*-$($script:name)*"
        }

        It "Error is attributed to the caller, not to Assert-ParameterExists" {
            try {
                Invoke-Caller -Name $script:name -Value ""
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }
    }

    Context "When ExtraMessage is provided" {
        It "Error message contains the extra message" {
            $extraMessage = 'Specify a target environment such as "staging" or "production".'

            {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value "" `
                    -ExtraMessage $extraMessage
            } | Should -Throw -ExpectedMessage "*$extraMessage*"
        }
    }
}
