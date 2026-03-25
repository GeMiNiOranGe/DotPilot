Describe "Assert-ArgumentExists" -Tag "Assert-ArgumentExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\ArgumentNullOrEmptyException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-ArgumentExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Name,
                [AllowEmptyString()]
                [string]$Value,
                [string]$ExtraMessage
            )
            Assert-ArgumentExists `
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

        It "Throws ArgumentNullOrEmptyException when parameter value is empty" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ExceptionType ([ArgumentNullOrEmptyException])
        }

        It "Error message contains the parameter name" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ExpectedMessage "*'-$($script:name)'*"
        }

        It "Error is attributed to the caller, not to Assert-ArgumentExists" {
            try {
                Invoke-Caller -Name $script:name -Value ""
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }

        It "ErrorRecord has FullyQualifiedErrorId of 'ArgumentNullOrEmpty'" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ErrorId "ArgumentNullOrEmpty,Invoke-Caller"
        }
    }

    Context "When ExtraMessage is provided" {
        It "Error message contains the extra message" {
            $extraMessage = (
                "Specify a target environment such as 'development', " +
                "'testing', 'staging' or 'production'."
            )

            {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value "" `
                    -ExtraMessage $extraMessage
            } | Should -Throw -ExpectedMessage "*$extraMessage"
        }
    }
}
