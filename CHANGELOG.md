# Changelog

All notable changes to **DotPilot** will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.2.0] - April 18, 2026
<!-- MVP 2 -->

### Added
- Added `Write-Log` command for unified logging that supports console output, `.log` file, and `.jsonl` file formats simultaneously.
- Added `Write-ConsoleLog` command for lightweight, formatted console-only logging.
- Added `Assert-CommandExists` command to check whether a CLI tool is installed before use, replacing `Assert-CliInstalled`.
- Added `Assert-ArgumentExists`, `Assert-DirectoryExists`, `Assert-FileExists`, and `Assert-ParentDirectoryExists` commands for consistent input validation across scripts.
- Added `LogLevel` and `LogFormat` enums for type-safe logging configuration.

### Changed
- Split `DotPilot` into three focused submodules: `DotPilot.Core`, `DotPilot.ProjectScaffold`, and `DotPilot.Utilities`. Shared utilities and logging now live in `DotPilot.Core`; project scaffolding commands remain in `DotPilot.ProjectScaffold`.
- Renamed `Assert-CliInstalled` to `Assert-CommandExists` for clearer intent.
- Renamed the `-ExtraMessage` parameter to `-Reason` across all assertion commands for improved readability.
- `Write-Log` now requires `-LogFormat` when file logging is enabled; passing `None` as the format throws a clear error instead of silently producing no output.
- Timestamps in `.log` files now follow the ISO 8601 standard.
- Updated documentation for `Write-Log`, `Assert-ArgumentExists`, `Assert-CommandExists`, `Assert-DirectoryExists`, `Assert-FileExists`, and `Assert-ParentDirectoryExists` with complete parameter descriptions and usage examples.

### Removed
- Removed `ConsoleCallException` class as it is no longer used.

## [0.1.1] - February 26, 2026

### Added
- Added `AssertCliInstalled.Tests` test suite.
- Added `Microsoft.Data.SqlClient` package to `WinFormsThreeLayersArchitecture` template.

### Changed
- Renamed `CommandNotFoundException` to `CliToolNotInstalledException`.
- Removed `Dtos` layer and updated layer types to `classlib` in `WinFormsThreeLayersArchitecture` template.
- Updated `Directory.Build.props` to apply `PrivateAssets="compile"` for both `ProjectReference` and `PackageReference`.

## [0.1.0] - June 4, 2025
<!-- MVP 1 -->

### Added
- Added `DotnetTemplate` type.
- Added `Clean`, `WinFormsThreeLayers`, and `Default` architecture templates.
- Added `Initialize-LayeredDotnetProject` and `New-LayeredDotnetTemplate` commands.

## [0.0.0] - May 10, 2025

### Added
- Initial commit.
