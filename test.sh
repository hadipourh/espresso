#!/bin/bash

# Script to test all espresso examples and generate a combined hash
# This verifies that all examples produce consistent output
# Uses SHA3-256 for cryptographically secure hashing

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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
TIMEOUT_SECONDS=20  # 20 seconds timeout per example
HASH_ALGO="sha256" # Using SHA-256 for cryptographic security
EXPECTED_HASH="38a2f8a9bc03352cf54dac45cf4e2b99de5d083b010f99ccd748f7cfdb8336e4"  # Expected hash from original code (with tlex/o64.pla timeout)

# Check if espresso binary exists
if [ ! -f "$ESPRESSO_BIN" ]; then
    echo -e "${RED}Error: espresso binary not found at $ESPRESSO_BIN${NC}"
    echo "Please build the project first with: cd build && cmake .. && make"
    exit 1
fi

# Check if shasum is available (for SHA3-256)
if ! command -v shasum &> /dev/null; then
    echo -e "${RED}Error: shasum command not found${NC}"
    echo "Please install shasum (part of Perl's Digest::SHA module)"
    exit 1
fi

# Create temporary file for storing all hashes
TEMP_HASHES=$(mktemp)
trap "rm -f $TEMP_HASHES" EXIT

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Espresso Examples Test Suite                      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}Testing all examples in: ${NC}$EXAMPLES_BASE"
echo -e "${BLUE}Subdirectories: ${NC}examples, hard_examples, tlex"
echo -e "${BLUE}Using binary: ${NC}$ESPRESSO_BIN"
echo -e "${BLUE}Hash algorithm: ${NC}$HASH_ALGO"
echo -e "${BLUE}Timeout per example: ${NC}${TIMEOUT_SECONDS}s"
echo ""

# Count total files across all directories
total_files=0
for dir in "${EXAMPLE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        count=$(ls "$dir" 2>/dev/null | wc -l | tr -d ' ')
        total_files=$((total_files + count))
    fi
done

echo -e "${BLUE}Total files to test: ${NC}$total_files"
echo ""

# Counter for progress
current=0
failed=0
timed_out=0

# Process each example directory
for EXAMPLES_DIR in "${EXAMPLE_DIRS[@]}"; do
    if [ ! -d "$EXAMPLES_DIR" ]; then
        echo -e "${RED}Warning: Directory not found: $EXAMPLES_DIR${NC}"
        continue
    fi
    
    dir_name=$(basename "$EXAMPLES_DIR")
    echo -e "${BLUE}━━━ Testing $dir_name ━━━${NC}"
    
    # Process each example file
    for example_file in "$EXAMPLES_DIR"/*; do
        # Skip if not a file
        [ -f "$example_file" ] || continue
        
        filename=$(basename "$example_file")
        current=$((current + 1))
        
        # Record start time
        start_time=$(date +%s)
        
        # Run espresso with timeout and compute hash
        # Use gtimeout on macOS (from coreutils) or timeout on Linux
        if command -v gtimeout &> /dev/null; then
            timeout_cmd="gtimeout"
        elif command -v timeout &> /dev/null; then
            timeout_cmd="timeout"
        else
            timeout_cmd=""
        fi
        
        if [ -n "$timeout_cmd" ]; then
            # With timeout
            if output=$($timeout_cmd $TIMEOUT_SECONDS "$ESPRESSO_BIN" "$example_file" 2>/dev/null); then
                hash=$(echo "$output" | shasum -a 256 | awk '{print $1}')
                end_time=$(date +%s)
                elapsed=$((end_time - start_time))
                
                echo "$hash  $dir_name/$filename" >> "$TEMP_HASHES"
                printf "[%3d/%3d] %-30s %s (%.1fs)\n" "$current" "$total_files" "$dir_name/$filename" "$hash" "$elapsed"
            else
                exit_code=$?
                if [ $exit_code -eq 124 ]; then
                    # Timeout occurred
                    echo -e "${RED}[TIMEOUT]${NC} $dir_name/$filename (>${TIMEOUT_SECONDS}s)"
                    timed_out=$((timed_out + 1))
                else
                    echo -e "${RED}[FAILED]${NC} $dir_name/$filename"
                    failed=$((failed + 1))
                fi
            fi
        else
            # Without timeout (fallback)
            if output=$("$ESPRESSO_BIN" "$example_file" 2>/dev/null); then
                hash=$(echo "$output" | shasum -a 256 | awk '{print $1}')
                end_time=$(date +%s)
                elapsed=$((end_time - start_time))
                
                echo "$hash  $dir_name/$filename" >> "$TEMP_HASHES"
                printf "[%3d/%3d] %-30s %s (%.1fs)\n" "$current" "$total_files" "$dir_name/$filename" "$hash" "$elapsed"
            else
                echo -e "${RED}[FAILED]${NC} $dir_name/$filename"
                failed=$((failed + 1))
            fi
        fi
    done
    echo ""
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Compute final hash of all hashes combined
echo "Computing combined hash of all outputs..."
final_hash=$(sort "$TEMP_HASHES" | shasum -a 256 | awk '{print $1}')

# Display results
echo ""
echo "================================"
echo "Summary:"
echo "================================"
echo "Total files tested: $total_files"
echo "Successful: $((total_files - failed - timed_out))"
echo "Failed: $failed"
echo "Timed out: $timed_out"
echo ""
echo "Final combined hash ($HASH_ALGO):"
echo "$final_hash"
echo ""
echo "Expected hash (from original code):"
echo "$EXPECTED_HASH"
echo ""

# Verify hash matches expected
if [ "$final_hash" = "$EXPECTED_HASH" ]; then
    echo -e "${GREEN}✓ Hash verification PASSED - Output matches original code!${NC}"
    hash_match=true
else
    echo -e "${RED}✗ Hash verification FAILED - Output differs from original code!${NC}"
    hash_match=false
fi
echo ""

# Save results
results_file="test_results_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Espresso Test Results"
    echo "Date: $(date)"
    echo "Total files: $total_files"
    echo "Successful: $((total_files - failed - timed_out))"
    echo "Failed: $failed"
    echo "Timed out: $timed_out"
    echo "Final combined hash ($HASH_ALGO): $final_hash"
    echo "Expected hash: $EXPECTED_HASH"
    if [ "$hash_match" = true ]; then
        echo "Hash verification: PASSED ✓"
    else
        echo "Hash verification: FAILED ✗"
    fi
    echo ""
    echo "Individual hashes:"
    cat "$TEMP_HASHES"
} > "$results_file"

echo "Results saved to: $results_file"
    
    # Save detailed results
    RESULTS_FILE="$SCRIPT_DIR/test_results.txt"
    {
        echo "Espresso Examples Test Results"
        echo "Generated: $(date)"
        echo "Binary: $ESPRESSO_BIN"
        echo "Directories tested: examples, hard_examples, tlex"
        echo ""
        echo "Individual Example Hashes:"
        sort "$TEMP_HASHES"
        echo ""
        echo "Final Combined Hash: $final_hash"
    } > "$RESULTS_FILE"
    
    echo -e "Detailed results saved to: ${BLUE}$RESULTS_FILE${NC}"
    echo ""
    
    if [ $failed -eq 0 ] && [ $timed_out -eq 0 ] && [ "$hash_match" = true ]; then
        echo -e "${GREEN}✓ All tests passed successfully! Output matches original code.${NC}"
        exit 0
    elif [ $failed -gt 0 ] || [ $timed_out -gt 0 ]; then
        echo -e "${RED}✗ Some tests failed or timed out!${NC}"
        exit 1
    else
        echo -e "${RED}✗ Hash verification failed - output differs from original code!${NC}"
        exit 1
    fi
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: No hashes were generated${NC}"
    exit 1
fi
