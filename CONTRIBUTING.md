# Contributing to Espresso

Thank you for your interest in contributing to the Espresso Logic Minimizer project!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/espresso.git`
3. Create a branch for your changes: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- CMake 3.10 or higher
- C compiler (GCC or Clang)
- Standard build tools (make)

### Building

```bash
mkdir build
cd build
cmake ..
make -j8
```

## Code Standards

### Code Style

- Follow ANSI C99 standard
- Use the provided code formatter before committing:
  ```bash
  ./format.sh
  ```
- Maintain existing code style (4-space indentation, etc.)

### Testing

Before submitting changes, ensure all tests pass:

```bash
# Run comprehensive test suite
./test.sh
```

All 183 examples must pass, and the final hash must match the expected value to ensure functional compatibility with the original implementation.

### Making Changes

1. Keep changes focused and atomic
2. Preserve compatibility with the original Espresso behavior
3. Add tests for new features if applicable
4. Update documentation if needed

## Submitting Changes

1. Ensure your code follows the style guidelines
2. Run the test suite and verify all tests pass
3. Commit your changes with clear, descriptive messages
4. Push to your fork
5. Open a Pull Request with a clear description of your changes

## Pull Request Guidelines

- Describe what your changes do and why
- Reference any related issues
- Ensure CI checks pass
- Be responsive to feedback

## Questions?

Feel free to open an issue for questions or discussions about potential contributions.

## License

By contributing, you agree that your contributions will be licensed under the GNU General Public License v3.0.
