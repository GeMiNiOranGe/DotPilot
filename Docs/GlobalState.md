# `$global:DotPilot` - Global State

## Overview

`$global:DotPilot` is a **PSCustomObject** initialized once at global scope. It serves as the **central configuration store** for the DotPilot module - functions read their settings from here instead of requiring repeated parameters on every call.

The initialization block uses a guard check (`-not (Get-Variable ...)`) to ensure the state is **not overwritten** if the module is imported multiple times in the same session.

## Structure

```
$global:DotPilot
\---Log
    +---FileLogging   [bool]        Enable or disable writing logs to a file
    \---FileFormat    [LogFormat]   Output format of the log file
```

### `Log`

Configuration group for file-based logging behavior.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `FileLogging` | `bool` | `$false` | When `$true`, log entries are written to a file. When `$false`, output goes to the console only (or is suppressed, depending on the implementation). |
| `FileFormat` | `LogFormat` | `[LogFormat]::Log` | The format of the log file to be written. `[LogFormat]` is an enum - see valid values below. |

## `[LogFormat]` Enum

`FileFormat` accepts a value from the `[LogFormat]` enum. Refer to the enum definition in the module source for all available values. The default is `[LogFormat]::Log`.

| Value | Description |
|---|---|
| `None` | Disable file logging |
| `Log` | Write to a plain text `.log` file |
| `Json` | Write to a `.jsonl` file |

## Usage

### Reading configuration

```powershell
# Check whether file logging is enabled
$global:DotPilot.Log.FileLogging

# Get the current log format
$global:DotPilot.Log.FileFormat
```

### Changing configuration at runtime

```powershell
# Enable file logging
$global:DotPilot.Log.FileLogging = $true

# Switch to a different format (example)
$global:DotPilot.Log.FileFormat = [LogFormat]::Json
```

> **Note:** Changes made directly to `$global:DotPilot` only persist for the current session. For persistent defaults, set values after the module is imported - for example, in a profile script or an initialization block.

## Initialization Behavior

```powershell
if (-not (Get-Variable -Name 'DotPilot' -Scope Global -ErrorAction SilentlyContinue)) {
    # Only runs if $global:DotPilot does not yet exist
    $global:DotPilot = ...
}
```

| Scenario | Result |
| --- | --- |
| Module imported for the first time | State is created with default values |
| Module re-imported (`Import-Module -Force`) | State is **not** reset - current values are preserved |
| `$global:DotPilot` was set manually beforehand | State is **not** overwritten |

## Related

- See the `[LogFormat]` enum definition in the module source.
- Functions that write logs read `$global:DotPilot.Log` to determine their behavior.
