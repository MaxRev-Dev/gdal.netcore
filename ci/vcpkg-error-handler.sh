#!/bin/bash

# VCPKG Error Handler Script
# This script provides detailed error reporting when VCPKG package installations fail
#
# Usage: 
#   source vcpkg-error-handler.sh
#   show_vcpkg_errors [build_dir] [output_dir]
#
# OR as executable:
#   ./vcpkg-error-handler.sh [build_dir] [output_dir]
#
# Arguments:
#   build_dir - Optional. The build directory path (default: /build/build-unix)
#   output_dir - Optional. The output directory for artifacts (default: ./vcpkg-error-artifacts)

show_vcpkg_errors() {
    local build_dir="${1:-/build/build-unix}"
    local output_dir="${2:-$(pwd)/vcpkg-error-artifacts}"
    local vcpkg_installed="${build_dir}/vcpkg/installed"
    local vcpkg_buildtrees="${build_dir}/vcpkg/buildtrees"
    
    echo "=== VCPKG BUILD FAILED ===" >&2
    echo "Using build directory: $build_dir" >&2
    echo "Output directory for artifacts: $output_dir" >&2
    
    # Create output directory for error artifacts
    mkdir -p "$output_dir"
    
    echo "Searching for issue_body.md files..." >&2
    
    # Search for issue_body.md files in the installed directory
    local issue_files=()
    if [[ -d "$vcpkg_installed" ]]; then
        while IFS= read -r -d '' issue_file; do
            issue_files+=("$issue_file")
            echo "=== VCPKG ERROR DETAILS: $issue_file ===" >&2
            cat "$issue_file" >&2
            echo "=== END ERROR DETAILS ===" >&2
        done < <(find "$vcpkg_installed" -name "issue_body.md" -type f -print0 2>/dev/null)
    else
        echo "VCPKG installed directory not found: $vcpkg_installed" >&2
    fi
    
    echo "Searching for build logs..." >&2
    
    # Search for recent build logs in buildtrees directory
    local log_files=()
    if [[ -d "$vcpkg_buildtrees" ]]; then
        local count=0
        while IFS= read -r -d '' log_file && [[ $count -lt 10 ]]; do
            log_files+=("$log_file")
            echo "=== Recent build log: $log_file ===" >&2
            tail -50 "$log_file" >&2
            echo "=== END LOG ===" >&2
            ((count++))
        done < <(find "$vcpkg_buildtrees" -name "*.log" -type f -mtime -1 -print0 2>/dev/null)
    else
        echo "VCPKG buildtrees directory not found: $vcpkg_buildtrees" >&2
    fi
    
    # Create error artifact if we found any error files
    if [[ ${#issue_files[@]} -gt 0 ]] || [[ ${#log_files[@]} -gt 0 ]]; then
        echo "Creating error artifact..." >&2
        
        # Copy issue_body.md files
        for issue_file in "${issue_files[@]}"; do
            local rel_path="${issue_file#$vcpkg_installed/}"
            local dest_dir="$output_dir/issue_bodies/$(dirname "$rel_path")"
            mkdir -p "$dest_dir"
            cp "$issue_file" "$dest_dir/"
        done
        
        # Copy recent build logs
        for log_file in "${log_files[@]}"; do
            local rel_path="${log_file#$vcpkg_buildtrees/}"
            local dest_dir="$output_dir/build_logs/$(dirname "$rel_path")"
            mkdir -p "$dest_dir"
            cp "$log_file" "$dest_dir/"
        done
        
        # Create a summary file
        cat > "$output_dir/error_summary.txt" << EOF
VCPKG Build Error Summary
Generated: $(date)
Build Directory: $build_dir

Issue Body Files Found: ${#issue_files[@]}
$(printf '%s\n' "${issue_files[@]}")

Build Log Files Found: ${#log_files[@]}
$(printf '%s\n' "${log_files[@]}")

System Information:
OS: $(uname -a)
$(if command -v sw_vers >/dev/null 2>&1; then sw_vers; fi)
EOF
        
        # Create compressed artifact
        local artifact_name="vcpkg-error-$(date +%Y%m%d-%H%M%S).tar.gz"
        (cd "$(dirname "$output_dir")" && tar -czf "$artifact_name" "$(basename "$output_dir")")
        echo "Error artifact created: $(dirname "$output_dir")/$artifact_name" >&2
        
        # Also output the path for CI systems to use
        echo "VCPKG_ERROR_ARTIFACT_PATH=$(dirname "$output_dir")/$artifact_name" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
        echo "VCPKG_ERROR_ARTIFACT_DIR=$output_dir" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
    else
        echo "No error files found to create artifact" >&2
    fi
}

# Export the function so it can be used when sourced
export -f show_vcpkg_errors

# If script is executed directly (not sourced), call the function with provided arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_vcpkg_errors "$@"
fi