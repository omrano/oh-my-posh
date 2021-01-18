<#
        .SYNOPSIS
        Generates the prompt before each line in the console
#>

function Get-PoshCommand {
    $poshCommand = "$PSScriptRoot/bin/posh-windows-amd64.exe"
    if ($IsMacOS) {
        $poshCommand = "$PSScriptRoot/bin/posh-darwin-amd64"
    }
    if ($IsLinux) {
        $poshCommand = "$PSScriptRoot/bin/posh-linux-amd64"
    }
    return $poshCommand
}

# Set the right binary to executable before doing anything else
if ($PSVersionTable.PSEdition -eq "Core" -and !$IsWindows) {
    $executable = Get-PoshCommand
    Invoke-Expression -Command "chmod +x $executable"
}

function Set-PoshPrompt {
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $Theme
    )

    $config = ""
    if (Test-Path "$PSScriptRoot/themes/$Theme.omp.json") {
        $config = "$PSScriptRoot/themes/$Theme.omp.json"
    }
    elseif (Test-Path $Theme) {
        $config = (Resolve-Path -Path $Theme).Path
    }
    else {
        $config = "$PSScriptRoot/themes/jandedobbeleer.omp.json"
    }

    $poshCommand = Get-PoshCommand
    Invoke-Expression (& $poshCommand --init --shell=pwsh --config="$config")
}

function Get-PoshThemes {
    $esc = [char]27
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $logo = @'
   __  _____ _      ___  ___       ______         _      __
  / / |  _  | |     |  \/  |       | ___ \       | |     \ \
 / /  | | | | |__   | .  . |_   _  | |_/ /__  ___| |__    \ \
< <   | | | | '_ \  | |\/| | | | | |  __/ _ \/ __| '_ \    > >
 \ \  \ \_/ / | | | | |  | | |_| | | | | (_) \__ \ | | |  / /
  \_\  \___/|_| |_| \_|  |_/\__, | \_|  \___/|___/_| |_| /_/
                             __/ |
                            |___/
'@
    Write-Host $logo
    $poshCommand = Get-PoshCommand
    Get-ChildItem -Path "$PSScriptRoot\themes\*" -Include '*.omp.json' | Sort-Object Name | ForEach-Object -Process {
        Write-Host ("=" * $consoleWidth)
        Write-Host "$esc[1m$($_.BaseName)$esc[0m"
        Write-Host ""
        & $poshCommand -config $($_.FullName) -pwd $PWD
        Write-Host ""
    }
    Write-Host ("=" * $consoleWidth)
}

function Write-PoshTheme {
    $config = $global:PoshSettings.Theme
    $poshCommand = Get-PoshCommand
    & $poshCommand -config $config -print-config
}

# Helper function to create argument completion results
function New-CompletionResult {
    param(
        [Parameter(Mandatory)]
        [string]$CompletionText,
        [string]$ListItemText = $CompletionText,
        [System.Management.Automation.CompletionResultType]$CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue,
        [string]$ToolTip = $CompletionText
    )

    New-Object System.Management.Automation.CompletionResult $CompletionText, $ListItemText, $CompletionResultType, $ToolTip
}

function ThemeCompletion {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameter
    )
    $themes = Get-ChildItem -Path "$PSScriptRoot\themes\*" -Include '*.omp.json' | Sort-Object Name | Select-Object -Property @{
        label='BaseName'
        expression={$_.BaseName.TrimEnd(".omp")}
    }
    $themes |
    Where-Object { $_.BaseName.ToLower().StartsWith($wordToComplete.ToLower()); } |
    Select-Object -Unique -ExpandProperty BaseName |
    ForEach-Object { New-CompletionResult -CompletionText $_ }
}

Register-ArgumentCompleter `
    -CommandName Set-PoshPrompt `
    -ParameterName Theme `
    -ScriptBlock $function:ThemeCompletion
