#!/bin/bash

# Script to test all espresso examples with multiple modes
# This verifies that the modernized code produces identical output to the original implementation
# Uses SHA-256 for cryptographically secure hashing
# IMPORTANT: Examples are processed in deterministic sorted order to ensure
# consistent test execution across different systems, filesystems, and shells

set -e  # Exit on error

# Ensure consistent sorting across different locales
export LC_ALL=C

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
EXAMPLES_BASE="$SCRIPT_DIR/examples"
ESPRESSO_BIN="$BUILD_DIR/espresso"

# All example subdirectories
EXAMPLE_DIRS=(
    "$EXAMPLES_BASE/examples"
    "$EXAMPLES_BASE/hard_examples"
    "$EXAMPLES_BASE/tlex"
)

# Configuration
TIMEOUT_SECONDS=59  # 59 seconds timeout per example
HASH_ALGO="sha256" # Using SHA-256 for cryptographic security
EXPECTED_HASH="53f911764ba4d1799b25b43c20b23f08abe0df036fa8c76cccaf3854b8d7dd56"  # Expected combined hash for validation

# Espresso modes to test - cycling through different modes
# Each file gets tested with 2-3 different modes
# Modes cover: default, fast, strong, output phase optimization, single output, etc.
ESPRESSO_MODES=(
    ""                    # 0: Default mode (ESPRESSO algorithm)
    "-efast"              # 1: Fast minimization
    "-estrong"            # 2: Strong minimization
    "-Dopo"               # 3: Output phase optimization
    "-Dso"                # 4: Single output (no term sharing)
    "-eeat"               # 5: Eat mode
    "-enirr"              # 6: No irreducible cover
    "-Dsimplify"          # 7: Simplify only
)

# Hard examples should NOT use -Dexact as it's too time-consuming
# For hard examples, we'll use faster modes only
HARD_EXAMPLE_MODES=(
    ""                    # Default
    "-efast"              # Fast
    "-estrong"            # Strong
)

# Examples that should NOT use -Dopo (output phase optimization) due to timeout
# Add filenames here (without directory path)
DOPO_BLACKLIST=(
    "xparc"
    "bcc"
)

# Examples that should ONLY use specific modes
# Add entries in format: "filename:mode1 mode2 mode3"
SPECIFIC_MODE_FILES=(
    "o64.pla:-Dsimplify"
)

# Verify prerequisites
verify_prerequisites() {
    if [ ! -f "$ESPRESSO_BIN" ]; then
        echo -e "${RED}Error: espresso binary not found at $ESPRESSO_BIN${NC}"
        echo "Please build the project first with: cd build && cmake .. && make"
        exit 1
    fi

    if ! command -v shasum &> /dev/null; then
        echo -e "${RED}Error: shasum command not found${NC}"
        echo "Please install shasum (part of Perl's Digest::SHA module)"
        exit 1
    fi
}

# Determine timeout command availability
get_timeout_command() {
    if command -v gtimeout &> /dev/null; then
        echo "gtimeout"
    elif command -v timeout &> /dev/null; then
        echo "timeout"
    else
        echo ""
    fi
}

verify_prerequisites

# Create temporary file for storing all hashes
TEMP_HASHES=$(mktemp)
trap "rm -f $TEMP_HASHES" EXIT

# Print test suite header
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                 Espresso Examples Test Suite (Multi-Mode)                                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Testing all examples in: ${NC}$EXAMPLES_BASE"
    echo -e "${BLUE}Subdirectories: ${NC}examples, hard_examples, tlex"
    echo -e "${BLUE}Using binary: ${NC}$ESPRESSO_BIN"
    echo -e "${BLUE}Hash algorithm: ${NC}$HASH_ALGO"
    echo -e "${BLUE}Timeout per test: ${NC}${TIMEOUT_SECONDS}s"
    echo -e "${BLUE}Testing strategy: ${NC}Multiple modes per file"
    echo ""
}

# Count total files across all directories
count_total_files() {
    local total=0
    for dir in "${EXAMPLE_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
            total=$((total + count))
        fi
    done
    echo "$total"
}

# Check if filename is in blacklist
is_blacklisted() {
    local filename=$1
    for blacklisted in "${DOPO_BLACKLIST[@]}"; do
        if [ "$filename" = "$blacklisted" ]; then
            return 0
        fi
    done
    return 1
}

# Function to select modes for a given file
get_modes_for_file() {
    local dir_name=$1
    local file_index=$2
    local filename=$3
    
    # Check if this file has specific modes defined
    for entry in "${SPECIFIC_MODE_FILES[@]}"; do
        local file_part="${entry%%:*}"
        local modes_part="${entry#*:}"
        if [ "$file_part" = "$filename" ]; then
            echo "$modes_part"
            return
        fi
    done
    
    # For hard examples, use only fast modes (no -Dexact)
    if [ "$dir_name" = "hard_examples" ]; then
        echo "${HARD_EXAMPLE_MODES[@]}"
        return
    fi
    
    # For regular examples, cycle through modes based on file index
    local mode_count=${#ESPRESSO_MODES[@]}
    local mode1=${ESPRESSO_MODES[$((file_index % mode_count))]}
    local mode2=${ESPRESSO_MODES[$(((file_index + 1) % mode_count))]}
    local modes_to_use="$mode1 $mode2"
    
    # For every 3rd file, add a third mode
    if [ $((file_index % 3)) -eq 0 ]; then
        local mode3=${ESPRESSO_MODES[$(((file_index + 2) % mode_count))]}
        modes_to_use="$mode1 $mode2 $mode3"
    fi
    
    # Filter out -Dopo if file is in blacklist
    if is_blacklisted "$filename"; then
        modes_to_use=$(echo "$modes_to_use" | sed 's/-Dopo//g')
    fi
    
    echo $modes_to_use
}

# Run a single test with espresso
run_espresso_test() {
    local timeout_cmd=$1
    local mode=$2
    local example_file=$3
    
    if [ -n "$timeout_cmd" ]; then
        $timeout_cmd $TIMEOUT_SECONDS "$ESPRESSO_BIN" $mode "$example_file" 2>/dev/null
    else
        "$ESPRESSO_BIN" $mode "$example_file" 2>/dev/null
    fi
}

print_header

total_files=$(count_total_files)
timeout_cmd=$(get_timeout_command)

echo -e "${BLUE}Total files: ${NC}$total_files"
echo -e "${BLUE}Modes available: ${NC}${#ESPRESSO_MODES[@]} (regular), ${#HARD_EXAMPLE_MODES[@]} (hard examples)"
echo -e "${BLUE}File processing order: ${NC}Deterministic (sorted alphabetically)"
echo ""

# Counter for progress
current=0
failed=0
timed_out=0
total_tests_run=0

# Process each example directory
file_index=0
for EXAMPLES_DIR in "${EXAMPLE_DIRS[@]}"; do
    if [ ! -d "$EXAMPLES_DIR" ]; then
        echo -e "${RED}Warning: Directory not found: $EXAMPLES_DIR${NC}"
        continue
    fi
    
    dir_name=$(basename "$EXAMPLES_DIR")
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Testing $dir_name ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Process each example file in sorted order to ensure consistent execution across systems
    for example_file in $(find "$EXAMPLES_DIR" -maxdepth 1 -type f | sort); do
        [ -f "$example_file" ] || continue
        
        filename=$(basename "$example_file")
        current=$((current + 1))
        
        # Get modes to test for this file
        modes=($(get_modes_for_file "$dir_name" "$file_index" "$filename"))
        
        # Test each mode
        for mode in "${modes[@]}"; do
            total_tests_run=$((total_tests_run + 1))
            
            # Display mode name
            mode_name="${mode:-default}"
            
            # Record start time and run test
            start_time=$(date +%s)
            
            # Disable 'set -e' temporarily to capture exit code properly
            set +e
            output=$(run_espresso_test "$timeout_cmd" "$mode" "$example_file")
            exit_code=$?
            set -e
            
            # Process result and update counters
            if [ $exit_code -eq 0 ]; then
                hash=$(echo "$output" | shasum -a 256 | awk '{print $1}')
                end_time=$(date +%s)
                elapsed=$((end_time - start_time))
                
                echo "$hash  $dir_name/$filename $mode_name" >> "$TEMP_HASHES"
                printf "[%3d/%3d] %-25s %-15s %s (%.1fs)\n" "$current" "$total_files" "$dir_name/$filename" "$mode_name" "$hash" "$elapsed"
            elif [ -n "$timeout_cmd" ] && [ $exit_code -eq 124 ]; then
                echo -e "${RED}[TIMEOUT]${NC} $dir_name/$filename $mode (>${TIMEOUT_SECONDS}s)"
                timed_out=$((timed_out + 1))
            else
                echo -e "${RED}[FAILED]${NC} $dir_name/$filename $mode"
                failed=$((failed + 1))
            fi
        done
        
        file_index=$((file_index + 1))
    done
    echo ""
done

# Generate and save test report
generate_report() {
    local final_hash=$1
    local results_file="test_results_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Espresso Multi-Mode Test Results"
        echo "Date: $(date)"
        echo "Total files: $total_files"
        echo "Total tests run: $total_tests_run"
        echo "Successful: $((total_tests_run - failed - timed_out))"
        echo "Failed: $failed"
        echo "Timed out: $timed_out"
        echo ""
        echo "Mode coverage:"
        awk '{print $NF}' "$TEMP_HASHES" | sort | uniq -c | sort -rn
        echo ""
        echo "Final combined hash ($HASH_ALGO): $final_hash"
        echo ""
        echo "Individual test hashes:"
        sort "$TEMP_HASHES"
    } > "$results_file"
    
    echo "$results_file"
}

# Print summary and final results
print_summary() {
    local final_hash=$1
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Computing combined hash of all test outputs..."
    echo "Analyzing mode coverage..."
    
    local unique_modes=$(awk '{print $NF}' "$TEMP_HASHES" | sort -u | wc -l | tr -d ' ')
    
    echo ""
    echo "================================"
    echo "Summary:"
    echo "================================"
    echo "Total files: $total_files"
    echo "Total tests run: $total_tests_run"
    echo "Unique modes tested: $unique_modes"
    echo "Successful tests: $((total_tests_run - failed - timed_out))"
    echo "Failed: $failed"
    echo "Timed out: $timed_out"
    echo ""
    echo "Mode coverage:"
    awk '{print $NF}' "$TEMP_HASHES" | sort | uniq -c | sort -rn | head -20
    echo ""
    echo "Final combined hash ($HASH_ALGO):"
    echo "$final_hash"
    echo ""
}

# Print final status and exit
print_final_status() {
    local results_file=$1
    local final_hash=$2
    
    echo "Results saved to: $results_file"
    echo ""
    
    # Check if hash matches expected value
    if [ "$final_hash" != "$EXPECTED_HASH" ]; then
        echo -e "${RED}✗ Hash mismatch!${NC}"
        echo -e "${RED}  Expected: $EXPECTED_HASH${NC}"
        echo -e "${RED}  Got:      $final_hash${NC}"
        echo -e "${YELLOW}  This indicates the test outputs have changed.${NC}"
        exit 1
    fi
    
    if [ $failed -eq 0 ] && [ $timed_out -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed successfully!${NC}"
        echo -e "${GREEN}  Hash matches expected value: $EXPECTED_HASH${NC}"
        echo -e "${GREEN}  Output is identical to the original implementation${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed or timed out!${NC}"
        exit 1
    fi
}

# Main summary and reporting
final_hash=$(sort "$TEMP_HASHES" | shasum -a 256 | awk '{print $1}')
print_summary "$final_hash"
results_file=$(generate_report "$final_hash")
print_final_status "$results_file" "$final_hash"
