#!/bin/bash

# Security scanning script for local development
# This script runs various security checks locally before pushing code

set -e

echo "🔒 Starting security scan..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if Trivy is installed
check_trivy() {
    if ! command -v trivy &> /dev/null; then
        print_error "Trivy is not installed. Please install it first:"
        echo "  macOS: brew install trivy"
        echo "  Linux: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
        exit 1
    fi
    print_status "Trivy is installed"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Container scanning will be skipped."
        SKIP_CONTAINER_SCAN=true
    else
        print_status "Docker is installed"
    fi
}

# Scan filesystem for vulnerabilities
scan_filesystem() {
    print_status "Scanning filesystem for vulnerabilities..."
    trivy fs --severity CRITICAL,HIGH,MEDIUM --format table . || {
        print_warning "Filesystem scan found vulnerabilities. Check the output above."
    }
}

# Scan for secrets and configuration issues
scan_secrets() {
    print_status "Scanning for secrets and configuration issues..."
    trivy fs --scanners secret,config --severity CRITICAL,HIGH --format table . || {
        print_warning "Secret/config scan found issues. Check the output above."
    }
}

# Scan Docker images if Docker is available
scan_containers() {
    if [ "$SKIP_CONTAINER_SCAN" = true ]; then
        print_warning "Skipping container scan (Docker not available)"
        return
    fi
    
    print_status "Building and scanning Docker images..."
    
    # Build images for scanning
    if [ -f "./op-enclave/Dockerfile" ]; then
        print_status "Building op-enclave image..."
        docker build -t op-enclave:security-scan ./op-enclave
        print_status "Scanning op-enclave image..."
        trivy image --severity CRITICAL,HIGH --format table op-enclave:security-scan || {
            print_warning "op-enclave image scan found vulnerabilities"
        }
    fi
    
    if [ -f "./op-batcher/Dockerfile" ]; then
        print_status "Building op-batcher image..."
        docker build -t op-batcher:security-scan ./op-batcher
        print_status "Scanning op-batcher image..."
        trivy image --severity CRITICAL,HIGH --format table op-batcher:security-scan || {
            print_warning "op-batcher image scan found vulnerabilities"
        }
    fi
    
    if [ -f "./op-proposer/Dockerfile" ]; then
        print_status "Building op-proposer image..."
        docker build -t op-proposer:security-scan ./op-proposer
        print_status "Scanning op-proposer image..."
        trivy image --severity CRITICAL,HIGH --format table op-proposer:security-scan || {
            print_warning "op-proposer image scan found vulnerabilities"
        }
    fi
}

# Scan dependencies based on project type
scan_dependencies() {
    print_status "Scanning dependencies..."
    
    # Check for different types of dependency files
    if [ -f "package.json" ]; then
        print_status "Found package.json - scanning npm dependencies..."
        if command -v npm &> /dev/null; then
            npm audit --audit-level=high || {
                print_warning "npm audit found vulnerabilities"
            }
        else
            print_warning "npm not found, skipping npm audit"
        fi
    fi
    
    if [ -f "requirements.txt" ]; then
        print_status "Found requirements.txt - scanning Python dependencies..."
        if command -v pip &> /dev/null; then
            pip-audit --severity high || {
                print_warning "pip-audit found vulnerabilities"
            }
        else
            print_warning "pip not found, skipping pip-audit"
        fi
    fi
    
    if [ -f "go.mod" ]; then
        print_status "Found go.mod - scanning Go dependencies..."
        if command -v go &> /dev/null; then
            go list -json -deps . | trivy fs --severity CRITICAL,HIGH --format table - || {
                print_warning "Go dependencies scan found vulnerabilities"
            }
        else
            print_warning "go not found, skipping Go dependency scan"
        fi
    fi
    
    if [ -f "Cargo.toml" ]; then
        print_status "Found Cargo.toml - scanning Rust dependencies..."
        if command -v cargo &> /dev/null; then
            cargo audit --deny warnings || {
                print_warning "cargo audit found vulnerabilities"
            }
        else
            print_warning "cargo not found, skipping Rust dependency scan"
        fi
    fi
}

# Check for common security issues in code
check_code_security() {
    print_status "Checking for common security issues in code..."
    
    # Check for hardcoded secrets
    if grep -r -i "password\|secret\|key\|token" . --exclude-dir={.git,node_modules,target,dist} --exclude="*.lock" | grep -v "example\|test\|mock" > /dev/null; then
        print_warning "Potential hardcoded secrets found. Review the following files:"
        grep -r -l -i "password\|secret\|key\|token" . --exclude-dir={.git,node_modules,target,dist} --exclude="*.lock" | grep -v "example\|test\|mock" || true
    fi
    
    # Check for unsafe code patterns in Rust
    if [ -f "Cargo.toml" ]; then
        if command -v cargo &> /dev/null; then
            print_status "Running cargo clippy for security checks..."
            cargo clippy -- -D warnings || {
                print_warning "cargo clippy found issues"
            }
        fi
    fi
}

# Main execution
main() {
    echo "🔒 Security Scan for op-enclave"
    echo "================================"
    
    # Check prerequisites
    check_trivy
    check_docker
    
    # Run scans
    scan_filesystem
    scan_secrets
    scan_dependencies
    check_code_security
    scan_containers
    
    echo ""
    echo "✅ Security scan completed!"
    echo "📋 Review any warnings or errors above"
    echo "🔍 For detailed results, check the Security tab in GitHub"
}

# Run main function
main "$@" 