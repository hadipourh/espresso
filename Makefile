CMAKE := $(shell if command -v nix >/dev/null 2>&1; then echo "nix develop --command cmake"; else echo "cmake"; fi)

build: build/espresso

build/espresso:
	$(CMAKE) -B build
	$(CMAKE) --build build

install: build/espresso
	$(CMAKE) --install build

test: build/espresso
	./test.sh

clean:
	rm -rf CMakeCache.txt CMakeFiles/ build/ cmake_install.cmake test_results_*.txt


.PHONY: build install test clean
