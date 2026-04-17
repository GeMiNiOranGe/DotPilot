Project: DotPilot

Type:
CLI tooling (project scaffolding, utility scripts)

Purpose:
- Primary: Automate creation of project structures using JSON templates to reduce repetitive setup work.
- Secondary: utility automation (file operations, repo cloning)

Core Idea:
- DotPilot.Core provides shared utilities (validation, logging, common helpers)
- DotPilot.ProjectScaffold is a JSON template–driven scaffolding system that generates structures for .NET, Node.js, ... to support different architecture patterns (e.g. layered, clean architecture)

Tech Stack:
PowerShell 7, modular PowerShell modules, Pester, platyPS

Architecture:
- Multi-module structure
- Standard PowerShell module layout (Public/Private/Classes)
- CLI entry point for command execution

Flow:
- Project scaffolding: CLI --> parse JSON template --> generate structure/files
- Utilities: CLI --> File operations or repo cloning

Key Decisions:
- JSON templates as the config format for simplicity and developer familiarity
- Use PowerShell for native automation in .NET ecosystem
- Modular monorepo-style structure instead of single script

Status:
- Learning-focused, not production-ready
- No real-world usage validation
- Limited template ecosystem

Meta:
- Team: individual
- Scale: small (2-3 modules)
- Timeline: ~3 months total (ongoing, See CHANGELOG for details)
    - MVP 1 - v0.1.* (Initial build): ~1 month
    - MVP 2 - v0.2.* (Stabilization): ~2 months
- Role: Solo developer; used AI assistance for PowerShell syntax learning.
