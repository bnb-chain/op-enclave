# Security Scanning and Vulnerability Detection

This document describes the security scanning setup for the op-enclave project, which automatically detects vulnerabilities during build time and development.

## Overview

The project includes multiple layers of security scanning:

1. **Automated CI/CD Scanning** - GitHub Actions workflows that run on every push and pull request
2. **Local Development Scanning** - Scripts and pre-commit hooks for local vulnerability detection
3. **Container Security** - Docker image vulnerability scanning
4. **Dependency Scanning** - Automated checks for vulnerable dependencies

## Automated CI/CD Security Scanning

### GitHub Actions Workflows

#### 1. Enhanced Docker Release Workflow (`.github/workflows/docker-release.yml`)

The existing Docker release workflow has been enhanced with:

- **Pre-build security scan**: Filesystem vulnerability scanning before building images
- **Post-build container scan**: Vulnerability scanning of built Docker images
- **SARIF reporting**: Results uploaded to GitHub Security tab

#### 2. Dedicated Security Scan Workflow (`.github/workflows/security-scan.yml`)

A comprehensive security workflow that runs:

- **Trivy filesystem scanning**: Detects vulnerabilities in source code and dependencies
- **CodeQL analysis**: Static analysis for JavaScript, Python, and Go
- **Dependency scanning**: Snyk-based scanning for npm, pip, and Go dependencies
- **Container scanning**: Vulnerability scanning of all Docker images
- **Weekly scheduled scans**: Automatic security checks every Sunday

### Triggers

Security scans run automatically on:
- Every push to `main` and `develop` branches
- Every pull request to `main` and `develop` branches
- Weekly scheduled scans (Sundays at 2 AM UTC)
- Manual trigger via GitHub Actions UI

## Local Development Security Scanning

### Prerequisites

Install required security tools:

```bash
# macOS
brew install trivy
brew install pre-commit

# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
pip install pre-commit

# Install pre-commit hooks
pre-commit install
```

### Manual Security Scanning

Run the comprehensive security scan script:

```bash
./scripts/security-scan.sh
```

This script performs:
- Filesystem vulnerability scanning
- Secret and configuration scanning
- Dependency vulnerability checks
- Container image scanning (if Docker is available)
- Code security pattern checks

### Pre-commit Hooks

The project includes pre-commit hooks that automatically run security checks before each commit:

```bash
# Install pre-commit hooks
pre-commit install

# Run all hooks manually
pre-commit run --all-files
```

Available hooks:
- **Trivy filesystem scan**: Vulnerability scanning
- **Trivy secret scan**: Secret and configuration scanning
- **Bandit**: Python security analysis
- **Cargo audit**: Rust dependency vulnerabilities
- **Cargo clippy**: Rust security warnings
- **GoSec**: Go security analysis
- **NPM audit**: Node.js dependency vulnerabilities

## Security Tools Used

### 1. Trivy (Aqua Security)

**Purpose**: Comprehensive vulnerability scanner for containers, filesystems, and dependencies

**Features**:
- OS package vulnerability scanning
- Language-specific dependency scanning
- Secret detection
- Configuration file scanning
- Container image scanning

**Usage**:
```bash
# Scan filesystem
trivy fs --severity CRITICAL,HIGH .

# Scan Docker image
trivy image --severity CRITICAL,HIGH myimage:latest

# Scan for secrets
trivy fs --scanners secret,config .
```

### 2. CodeQL (GitHub)

**Purpose**: Static analysis for source code vulnerabilities

**Supported Languages**:
- JavaScript/TypeScript
- Python
- Go
- Java
- C/C++

**Features**:
- SQL injection detection
- Cross-site scripting (XSS)
- Path traversal vulnerabilities
- Memory safety issues
- And many more...

### 3. Snyk

**Purpose**: Dependency vulnerability scanning

**Supported Ecosystems**:
- npm (Node.js)
- pip (Python)
- Go modules
- Maven (Java)
- NuGet (.NET)

### 4. Language-Specific Tools

#### Rust
- **cargo audit**: Scans for known vulnerabilities in Rust dependencies
- **cargo clippy**: Detects security-related code patterns

#### Python
- **bandit**: Security linter for Python code
- **safety**: Checks Python dependencies against known vulnerabilities

#### Go
- **gosec**: Security linter for Go code
- **govulncheck**: Official Go vulnerability scanner

#### Node.js
- **npm audit**: Built-in vulnerability scanner for npm packages

## Security Configuration

### Severity Levels

The scanning is configured with the following severity levels:

- **CRITICAL**: Must be fixed immediately
- **HIGH**: Should be fixed as soon as possible
- **MEDIUM**: Should be reviewed and fixed when convenient
- **LOW**: Informational issues

### Exclusions

Some files and directories are excluded from scanning:

- `.git/` - Version control files
- `node_modules/` - Node.js dependencies
- `target/` - Rust build artifacts
- `dist/` - Build output directories
- Test files and mock data

## Viewing Security Results

### GitHub Security Tab

All scan results are automatically uploaded to the GitHub Security tab:

1. Go to your repository on GitHub
2. Click on the "Security" tab
3. View alerts from various scanning tools
4. Review and triage security findings

### Local Reports

When running scans locally, results are displayed in the terminal. For detailed reports:

```bash
# Generate detailed Trivy report
trivy fs --format json --output trivy-report.json .

# Generate SARIF report for GitHub
trivy fs --format sarif --output trivy-results.sarif .
```

## Responding to Security Findings

### 1. Critical and High Severity Issues

**Immediate Actions**:
- Review the vulnerability details
- Assess the impact on your application
- Implement fixes or workarounds
- Update dependencies if necessary
- Re-run security scans to verify fixes

### 2. Medium and Low Severity Issues

**Recommended Actions**:
- Review findings during regular development cycles
- Prioritize based on your application's security requirements
- Plan fixes for upcoming releases

### 3. False Positives

If you encounter false positives:

1. Document the false positive with justification
2. Add appropriate exclusions to scanning configuration
3. Consider creating custom rules if needed

## Best Practices

### Development Workflow

1. **Always run local scans** before pushing code
2. **Review security alerts** in GitHub Security tab
3. **Fix high and critical issues** before merging PRs
4. **Keep dependencies updated** regularly
5. **Use security-focused code reviews**

### Dependency Management

1. **Regular updates**: Keep dependencies up to date
2. **Vulnerability monitoring**: Subscribe to security advisories
3. **Minimal dependencies**: Only include necessary packages
4. **Lock files**: Use lock files to ensure reproducible builds

### Container Security

1. **Base image selection**: Use minimal, security-focused base images
2. **Regular updates**: Keep base images updated
3. **Multi-stage builds**: Reduce attack surface
4. **Non-root users**: Run containers as non-root users when possible

## Troubleshooting

### Common Issues

#### Trivy Installation Issues
```bash
# macOS
brew install trivy

# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

#### Pre-commit Hook Failures
```bash
# Update pre-commit hooks
pre-commit autoupdate

# Run specific hook
pre-commit run trivy_fs --all-files
```

#### Docker Scanning Issues
```bash
# Ensure Docker is running
docker info

# Build image for scanning
docker build -t test-image .
trivy image test-image
```

### Getting Help

- **Trivy Documentation**: https://aquasecurity.github.io/trivy/
- **CodeQL Documentation**: https://codeql.github.com/docs/
- **GitHub Security**: https://docs.github.com/en/code-security
- **Pre-commit**: https://pre-commit.com/

## Contributing to Security

To improve the security scanning setup:

1. **Add new tools**: Propose additional security tools
2. **Update configurations**: Improve scanning rules and exclusions
3. **Document findings**: Share security insights with the team
4. **Automate more**: Identify opportunities for additional automation

## Security Contacts

For security-related questions or to report security issues:

- Create an issue in the repository
- Contact the security team directly
- Follow the project's security policy

---

**Note**: This security scanning setup is designed to catch common vulnerabilities but is not a substitute for proper security practices, code reviews, and penetration testing. 