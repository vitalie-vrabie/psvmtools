# Contributing to PSHVTools

Thank you for your interest in contributing to PSHVTools! This document provides guidelines and instructions for contributing.

## ?? Getting Started

### Prerequisites

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Hyper-V installed and configured
- 7-Zip (for backup compression)
- Inno Setup 6 (for building installer)
- Git

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/vitalie-vrabie/pshvtools.git
   cd pshvtools
   ```

2. **Install development tools**
   ```powershell
   # Install Pester for testing
   Install-Module -Name Pester -Force -SkipPublisherCheck
   
   # Install PSScriptAnalyzer for linting
   Install-Module -Name PSScriptAnalyzer -Force
   ```

3. **Run tests**
   ```powershell
   Invoke-Pester -Path ./tests
   ```

4. **Import the module**
   ```powershell
   Import-Module ./scripts/pshvtools.psd1 -Force
   ```

## ?? Coding Standards

### PowerShell Style Guide

1. **Naming Conventions**
   - Use PascalCase for function names: `Invoke-VMBackup`
   - Use kebab-case for aliases: `hv-bak`, `fix-vhd-acl`
   - Use PascalCase for parameter names: `-NamePattern`, `-DestinationPath`

2. **Code Formatting**
   - Indent with 4 spaces (no tabs)
   - Opening braces on same line
   - Use approved PowerShell verbs (`Get-`, `Set-`, `New-`, `Invoke-`, etc.)

3. **Documentation**
   - Add comment-based help to all public functions
   - Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE`
   - Document complex logic with inline comments

4. **Error Handling**
   - Use `$ErrorActionPreference = 'Stop'` for critical operations
   - Provide meaningful error messages
   - Clean up resources in `finally` blocks

### Example Function Structure

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description of function.
        
    .DESCRIPTION
        Detailed description of what the function does.
        
    .PARAMETER ParameterName
        Description of the parameter.
        
    .EXAMPLE
        Verb-Noun -ParameterName "value"
        Description of what this example does.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('alias-name')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName
    )
    
    begin {
        # Initialization code
    }
    
    process {
        # Main logic
        if ($PSCmdlet.ShouldProcess($target, $action)) {
            # Perform action
        }
    }
    
    end {
        # Cleanup code
    }
}
```

## ?? Testing

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ./tests

# Run specific test file
Invoke-Pester -Path ./tests/pshvtools.Tests.ps1

# Run with code coverage
Invoke-Pester -Path ./tests -CodeCoverage ./scripts/*.ps1
```

### Writing Tests

- Use Pester 5.x syntax
- Place tests in the `tests/` directory
- Name test files with `.Tests.ps1` suffix
- Group related tests using `Describe` and `Context`
- Use meaningful test descriptions

Example:
```powershell
Describe 'Invoke-VMBackup' {
    Context 'Parameter Validation' {
        It 'Should accept NamePattern parameter' {
            # Test code
        }
    }
}
```

## ?? Git Workflow

### Branching Strategy

- `master` - Stable production code
- `develop` - Integration branch for features
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Critical production fixes

### Commit Messages

Use conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style/formatting
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Build/tool changes

**Examples:**
```
feat(backup): add differential backup support
fix(restore): handle missing network switches gracefully
docs(readme): update installation instructions
```

### Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Make your changes**
   - Write code
   - Add tests
   - Update documentation

3. **Run tests and linting**
   ```powershell
   Invoke-Pester -Path ./tests
   Invoke-ScriptAnalyzer -Path ./scripts -Recurse
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/my-new-feature
   ```

6. **Create Pull Request**
   - Provide clear description
   - Reference related issues
   - Ensure CI checks pass

## ?? Reporting Bugs

### Before Reporting

1. Check existing issues
2. Test on latest version
3. Run health check: `Test-PSHVToolsEnvironment`

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. With parameters '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment**
- OS: [e.g., Windows 11 Pro]
- PowerShell Version: [e.g., 5.1.19041.4648]
- PSHVTools Version: [e.g., 1.0.9]
- Hyper-V Version:

**Additional context**
Add any other context about the problem.
```

## ?? Feature Requests

We welcome feature requests! Please:

1. Check existing feature requests
2. Describe the use case
3. Explain expected behavior
4. Consider implementation impact

## ?? Building and Releasing

### Building Locally

```powershell
# Build installer
./build.ps1

# Build with clean
./build.ps1 -Clean

# Build without version check
./build.ps1 -SkipVersionCheck

# Dry run
./build.ps1 -WhatIf
```

### Version Management

Version is managed in `version.json`:

```json
{
  "version": "1.0.9",
  "stableVersion": "1.0.8",
  "releaseDate": "2026-01-17"
}
```

Update version in `version.json`, then update:
- `scripts/pshvtools.psd1`
- `installer/PSHVTools-Installer.iss`
- `CHANGELOG.md`

### Release Process

1. Update version in `version.json`
2. Update `CHANGELOG.md`
3. Update `RELEASE_NOTES.md`
4. Run version consistency check: `./tests/Test-VersionConsistency.ps1`
5. Build and test: `./build.ps1`
6. Commit changes: `git commit -m "chore: bump version to X.Y.Z"`
7. Create tag: `git tag -a vX.Y.Z -m "Release X.Y.Z"`
8. Push: `git push && git push --tags`
9. GitHub Actions will create release automatically

## ?? Getting Help

- GitHub Issues: https://github.com/vitalie-vrabie/pshvtools/issues
- Discussions: https://github.com/vitalie-vrabie/pshvtools/discussions

## ?? Code of Conduct

Be respectful, constructive, and professional in all interactions.

## ?? License

By contributing, you agree that your contributions will be licensed under the MIT License.
