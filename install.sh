#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get inputs with defaults
VERSION="${INPUT_VERSION:-latest}"
INSTALL_PATH="${INPUT_INSTALL_PATH:-/opt/wasi-sdk}"
ADD_TO_PATH="${INPUT_ADD_TO_PATH:-true}"

# Detect architecture (Linux only)
detect_platform() {
    local arch=""
    
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    # Return in the format: arch-linux (as expected by WASI SDK releases)
    echo "${arch}-linux"
}

# Get the latest version from GitHub API
get_latest_version() {
    log_info "Fetching latest WASI SDK version from GitHub..." >&2
    
    local api_url="https://api.github.com/repos/WebAssembly/wasi-sdk/releases/latest"
    local latest_tag
    
    if command -v curl >/dev/null 2>&1; then
        latest_tag=$(curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
    elif command -v wget >/dev/null 2>&1; then
        latest_tag=$(wget -qO- "$api_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
    else
        log_error "Neither curl nor wget is available" >&2
        exit 1
    fi
    
    if [[ -z "$latest_tag" ]]; then
        log_error "Failed to fetch latest version" >&2
        exit 1
    fi
    
    # Extract version number from tag (e.g., "wasi-sdk-25" -> "25")
    echo "${latest_tag#wasi-sdk-}"
}

# Download and extract WASI SDK
install_wasi_sdk() {
    local version="$1"
    local platform="$2"
    local install_path="$3"
    
    # If version is "latest", get the actual latest version
    if [[ "$version" == "latest" ]]; then
        version=$(get_latest_version)
    fi
    
    log_info "Installing WASI SDK version $version for platform $platform"
    
    # Construct download URL
    local filename="wasi-sdk-${version}.0-${platform}.tar.gz"
    local download_url="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${version}/${filename}"
    
    log_info "Download URL: $download_url"
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    local temp_file="${temp_dir}/${filename}"
    
    # Download the archive
    log_info "Downloading WASI SDK..."
    if command -v curl >/dev/null 2>&1; then
        if ! curl -L -o "$temp_file" "$download_url"; then
            log_error "Failed to download WASI SDK"
            rm -rf "$temp_dir"
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -O "$temp_file" "$download_url"; then
            log_error "Failed to download WASI SDK"
            rm -rf "$temp_dir"
            exit 1
        fi
    else
        log_error "Neither curl nor wget is available"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Create install directory
    log_info "Creating install directory: $install_path"
    mkdir -p "$install_path"
    
    # Extract the archive
    log_info "Extracting WASI SDK..."
    if ! tar -xzf "$temp_file" -C "$install_path" --strip-components=1; then
        log_error "Failed to extract WASI SDK"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    log_success "WASI SDK $version installed to $install_path"
    
    # Set outputs
    echo "wasi-sdk-path=$install_path" >> "$GITHUB_OUTPUT"
    echo "wasi-sdk-version=$version" >> "$GITHUB_OUTPUT"
    echo "clang-path=$install_path/bin/clang" >> "$GITHUB_OUTPUT"
    echo "sysroot-path=$install_path/share/wasi-sysroot" >> "$GITHUB_OUTPUT"
}

# Add to PATH if requested
add_to_path() {
    local install_path="$1"
    local bin_path="${install_path}/bin"
    
    if [[ "$ADD_TO_PATH" == "true" ]]; then
        log_info "Adding WASI SDK to PATH"
        echo "$bin_path" >> "$GITHUB_PATH"
        
        # Also set environment variables for convenience
        echo "WASI_SDK_PATH=$install_path" >> "$GITHUB_ENV"
        echo "CC=$install_path/bin/clang --sysroot=$install_path/share/wasi-sysroot" >> "$GITHUB_ENV"
        echo "CXX=$install_path/bin/clang++ --sysroot=$install_path/share/wasi-sysroot" >> "$GITHUB_ENV"
        
        log_success "WASI SDK added to PATH and environment variables set"
    fi
}

# Verify installation
verify_installation() {
    local install_path="$1"
    local clang_path="${install_path}/bin/clang"
    local sysroot_path="${install_path}/share/wasi-sysroot"
    
    log_info "Verifying installation..."
    
    if [[ ! -f "$clang_path" ]]; then
        log_error "clang not found at $clang_path"
        exit 1
    fi
    
    if [[ ! -d "$sysroot_path" ]]; then
        log_error "WASI sysroot not found at $sysroot_path"
        exit 1
    fi
    
    # Test clang version
    local clang_version
    clang_version=$("$clang_path" --version | head -n1)
    log_success "Installation verified: $clang_version"
    
    # Show some useful paths
    log_info "WASI SDK installed at: $install_path"
    log_info "Clang executable: $clang_path"
    log_info "WASI sysroot: $sysroot_path"
}

# Main execution
main() {
    log_info "Starting WASI SDK installation..."
    
    local platform
    platform=$(detect_platform)
    log_info "Detected platform: $platform"
    
    install_wasi_sdk "$VERSION" "$platform" "$INSTALL_PATH"
    add_to_path "$INSTALL_PATH"
    verify_installation "$INSTALL_PATH"
    
    log_success "WASI SDK installation completed successfully!"
}

# Run main function
main "$@" 