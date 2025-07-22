#!/bin/bash

# Security tools installation script for op-enclave
# This script installs all necessary security scanning tools

set -e

echo "🔧 Installing security scanning tools..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_status "Detected OS: $OS"
}

# Install Trivy
install_trivy() {
    print_header "Installing Trivy vulnerability scanner..."
    
    if command -v trivy &> /dev/null; then
        print_status "Trivy is already installed"
        trivy --version
        return
    fi
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            brew install trivy
        else
            print_error "Homebrew is required for macOS installation"
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    print_status "Trivy installed successfully"
    trivy --version
}

# Install pre-commit
install_precommit() {
    print_header "Installing pre-commit..."
    
    if command -v pre-commit &> /dev/null; then
        print_status "pre-commit is already installed"
        pre-commit --version
        return
    fi
    
    if command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    elif command -v pip &> /dev/null; then
        pip install pre-commit
    else
        print_error "pip is required for pre-commit installation"
        exit 1
    fi
    
    print_status "pre-commit installed successfully"
    pre-commit --version
}

# Install language-specific security tools
install_language_tools() {
    print_header "Installing language-specific security tools..."
    
    # Rust tools
    if command -v cargo &> /dev/null; then
        print_status "Installing Rust security tools..."
        cargo install cargo-audit || print_warning "cargo-audit installation failed"
    fi
    
    # Python tools
    if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
        print_status "Installing Python security tools..."
        pip3 install bandit safety || pip install bandit safety || print_warning "Python security tools installation failed"
    fi
    
    # Go tools
    if command -v go &> /dev/null; then
        print_status "Installing Go security tools..."
        go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest || print_warning "gosec installation failed"
        go install golang.org/x/vuln/cmd/govulncheck@latest || print_warning "govulncheck installation failed"
    fi
    
    # Node.js tools
    if command -v npm &> /dev/null; then
        print_status "Installing Node.js security tools..."
        npm install -g snyk || print_warning "snyk installation failed"
    fi
}

# Install pre-commit hooks
install_hooks() {
    print_header "Installing pre-commit hooks..."
    
    if [ -f ".pre-commit-config.yaml" ]; then
        pre-commit install
        print_status "Pre-commit hooks installed successfully"
    else
        print_warning "No .pre-commit-config.yaml found, skipping hook installation"
    fi
}

# Verify installations
verify_installations() {
    print_header "Verifying installations..."
    
    local failed_checks=0
    
    # Check Trivy
    if command -v trivy &> /dev/null; then
        print_status "✅ Trivy is installed"
    else
        print_error "❌ Trivy is not installed"
        ((failed_checks++))
    fi
    
    # Check pre-commit
    if command -v pre-commit &> /dev/null; then
        print_status "✅ pre-commit is installed"
    else
        print_error "❌ pre-commit is not installed"
        ((failed_checks++))
    fi
    
    # Check language tools
    if command -v cargo-audit &> /dev/null; then
        print_status "✅ cargo-audit is installed"
    else
        print_warning "⚠️  cargo-audit is not installed (Rust projects only)"
    fi
    
    if command -v bandit &> /dev/null; then
        print_status "✅ bandit is installed"
    else
        print_warning "⚠️  bandit is not installed (Python projects only)"
    fi
    
    if command -v gosec &> /dev/null; then
        print_status "✅ gosec is installed"
    else
        print_warning "⚠️  gosec is not installed (Go projects only)"
    fi
    
    if command -v snyk &> /dev/null; then
        print_status "✅ snyk is installed"
    else
        print_warning "⚠️  snyk is not installed (Node.js projects only)"
    fi
    
    if [ $failed_checks -eq 0 ]; then
        print_status "🎉 All core security tools installed successfully!"
    else
        print_error "❌ Some installations failed. Please check the errors above."
        exit 1
    fi
}

# Show next steps
show_next_steps() {
    print_header "Next Steps"
    echo ""
    echo "1. Run a security scan:"
    echo "   ./scripts/security-scan.sh"
    echo ""
    echo "2. Install pre-commit hooks (if not already done):"
    echo "   pre-commit install"
    echo ""
    echo "3. Run pre-commit hooks manually:"
    echo "   pre-commit run --all-files"
    echo ""
    echo "4. Read the security documentation:"
    echo "   cat SECURITY.md"
    echo ""
    echo "5. Configure your IDE to show security warnings"
    echo ""
    print_status "Security tools installation completed!"
}

# Main execution
main() {
    echo "🔧 Security Tools Installation for op-enclave"
    echo "============================================="
    echo ""
    
    detect_os
    install_trivy
    install_precommit
    install_language_tools
    install_hooks
    verify_installations
    show_next_steps
}

# Run main function
main "$@" 