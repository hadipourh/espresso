# Espresso Logic Minimizer - Modernized Edition

A modernized version of the Espresso heuristic logic minimizer with ANSI C conformance and enhanced reliability.

## About

This repository contains a maintained and modernized version of the Espresso logic minimizer, originally developed at the University of California, Berkeley. Espresso is a heuristic multi-valued PLA (Programmable Logic Array) minimizer that has been widely used in electronic design automation and logic synthesis.

### Original Source

The original Espresso implementation was developed by the University of California, Berkeley and is available from:
- Official Distribution: https://ptolemy.berkeley.edu/projects/embedded/pubs/downloads/espresso/index.htm
- Copyright (c) 1988, 1989, Regents of the University of California

The original software was distributed under a permissive BSD-style license allowing use, copying, and preparation of derivative works.

## What's New in This Version

This modernized version addresses several improvements while maintaining 100% functional compatibility with the original implementation:

### Code Modernization

- **ANSI C Compliance**: Converted all Kernighan & Ritchie (K&R) C function declarations to ANSI C standard
  - Original: 2,173 compiler warnings on modern compilers (AppleClang 17.0.0)
  - Modernized: 0 warnings with strict compilation flags
  
- **Enhanced Type Safety**: Modern function prototypes with explicit parameter types

- **Improved Maintainability**: Clearer function signatures for easier understanding and maintenance

### Verification

All changes have been rigorously verified to ensure zero functional changes:
- Tested against 183 example files across three test suites
- Binary-identical output verified using SHA-256 hashing
- All modifications preserve original algorithms and logic flow

## Building

### Prerequisites

- CMake 3.10 or higher
- C compiler (GCC, Clang, or compatible)
- Make or Ninja build system

### Build Instructions

```bash
# Create build directory
mkdir build
cd build

# Configure with CMake
cmake ..

# Build (using parallel jobs for faster compilation)
make -j8

# The espresso binary will be in the build directory
```

## Usage

After building, you can run Espresso on PLA files:

```bash
cd build

# Basic minimization (outputs to stdout)
./espresso ../examples/examples/b2

# Save output to a file
./espresso ../examples/examples/alu2 > minimized.pla

# Get help and see all available options
./espresso

# Use exact minimization algorithm for optimal results
./espresso -Dexact ../examples/examples/b3

# Enable execution trace for detailed progress information
./espresso -t input.pla

# Show execution summary with timing and statistics
./espresso -s input.pla

# Advanced: Exact algorithm with strong minimization and fd output format
./espresso -Dexact -estrong -ofd input.pla
```

The output is a minimized PLA representation in standard format. For complete command-line options, run `./espresso` without arguments. For PLA file format specification, see `man/espresso.5`.

### Common Options

- `-Dexact` - Use exact minimization algorithm (optimal but slower)
- `-Dmany` - Use heuristic minimization (faster, near-optimal)
- `-estrong` - Use strong minimization strategy
- `-efast` - Use fast minimization strategy  
- `-s` - Print execution summary
- `-t` - Print execution trace
- `-ofd`, `-of`, `-ofr` - Select output format

### Examples

The repository includes comprehensive example files in three categories:

- `examples/examples/` - Standard test cases (123 files)
- `examples/hard_examples/` - Computationally intensive cases (19 files)
- `examples/tlex/` - Additional test cases (41 files)

### Testing

A comprehensive test script is provided to verify the correctness of the implementation:

```bash
# Run all tests (183 examples)
cd espresso
./test.sh
```

The test script will:
- Execute Espresso on all 183 example files
- Apply a 20-second timeout per example to handle computationally intensive cases
- Compute SHA-256 hashes of all outputs
- Verify the combined hash matches the expected value from the original implementation
- Report success/failure status with detailed timing information

Expected output:
```
Total files tested: 183
Successful: 182
Failed: 0
Timed out: 1

Hash verification PASSED - Output matches original code!
```

## Documentation

- Manual pages are available in `man/espresso.1` and `man/espresso.5`
- Original documentation is preserved in the `man/` directory
- Format specification: `man/espresso.5`

## Project Structure

```
espresso/
├── espresso/           # Core source files
├── utility/            # Utility functions and headers
├── examples/           # Test cases and examples
│   ├── examples/       # Standard examples
│   ├── hard_examples/  # Computationally intensive examples
│   └── tlex/          # Additional test cases
├── man/               # Manual pages
├── CMakeLists.txt     # Build configuration
└── test.sh            # Comprehensive test suite
```

## License

This modernized version is released under the GNU General Public License v3.0 (GPLv3).

The original Espresso software is copyright (c) 1988, 1989, Regents of the University of California, and was distributed under a permissive BSD-style license. The original copyright notice and license terms have been preserved in `utility/copyright.h`.

As required by the original license:
```
Copyright (c) 1988, 1989, Regents of the University of California.
All rights reserved.

Use and copying of this software and preparation of derivative works
based upon this software are permitted. However, any distribution of
this software or derivative works must include the above copyright notice.
```

The derivative work in this repository includes the required copyright notice and is distributed under GPLv3, which is compatible with the original BSD-style license.

## Contributing

Contributions are welcome. When contributing, please:

- Maintain ANSI C compliance
- Ensure all changes pass the test suite
- Preserve compatibility with the original Espresso behavior
- Follow the existing code style
- Include appropriate tests for new features

## Acknowledgments

- Original authors and contributors at UC Berkeley
- The OCT Tools Distribution 3.0 team
- CHIPS Alliance for their Espresso repository (https://github.com/chipsalliance/espresso)
- All contributors to the Espresso project over the decades

## Contact

For issues, questions, or contributions related to this modernized version, please use the GitHub issue tracker.

## References

- Original Espresso Distribution: https://ptolemy.berkeley.edu/projects/embedded/pubs/downloads/espresso/index.htm
- UC Berkeley Embedded Systems: https://ptolemy.berkeley.edu/projects/embedded/
