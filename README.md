# Install WASI SDK GitHub Action

This is a custom GitHub Action for use in your workflows that will install the [WASI SDK](https://github.com/WebAssembly/wasi-sdk) toolchain for WebAssembly development.

## Features

- ✅ Supports all major platforms (Linux, macOS, Windows)
- ✅ Supports multiple architectures (x86_64, arm64)
- ✅ Automatically detects platform and architecture
- ✅ Downloads and installs the specified version of WASI SDK
- ✅ Optionally adds WASI SDK to PATH
- ✅ Sets up convenient environment variables
- ✅ Provides output variables for use in subsequent steps
- ✅ Comprehensive error handling and logging

## Usage

### Basic Usage

```yaml
- name: Install WASI SDK
  uses: konsumer/install-wasi-sdk@v1
```

### Advanced Usage

```yaml
- name: Install WASI SDK
  uses: konsumer/install-wasi-sdk@v1
  with:
    version: '25'
    install-path: '/opt/wasi-sdk'
    add-to-path: 'true'
```

### Complete Workflow Example

```yaml
name: Build WebAssembly with WASI SDK

on:
  push:
    branches:
      [
        main,
      ]
  pull_request:
    branches:
      [
        main,
      ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install WASI SDK
        uses: konsumer/install-wasi-sdk@v1
        with:
          version: '25'

      - name: Build WebAssembly module
        run:
          |
          clang hello.c -o hello.wasm
          # or using the environment variable
          $CC hello.c -o hello.wasm

      - name: Test WebAssembly module
        run:
          |
          wasmtime hello.wasm
```

## Inputs

| Input          | Description                                          | Required | Default         |
| -------------- | ---------------------------------------------------- | -------- | --------------- |
| `version`      | WASI SDK version to install (e.g., "25", "24", "23") | No       | `latest`        |
| `install-path` | Directory to install WASI SDK to                     | No       | `/opt/wasi-sdk` |
| `add-to-path`  | Add WASI SDK bin directory to PATH                   | No       | `true`          |

## Outputs

| Output             | Description                            |
| ------------------ | -------------------------------------- |
| `wasi-sdk-path`    | Path to the installed WASI SDK         |
| `wasi-sdk-version` | Version of WASI SDK that was installed |
| `clang-path`       | Path to the clang executable           |
| `sysroot-path`     | Path to the WASI sysroot               |

## Environment Variables

When `add-to-path` is `true`, the action sets up the following environment variables:

- `WASI_SDK_PATH`: Path to the WASI SDK installation
- `CC`: Clang compiler with WASI sysroot configured
- `CXX`: Clang++ compiler with WASI sysroot configured

## Platform Support

This action supports the following platforms:

| OS      | Architecture          | Support |
| ------- | --------------------- | ------- |
| Linux   | x86_64                | ✅      |
| Linux   | arm64                 | ✅      |
| macOS   | x86_64                | ✅      |
| macOS   | arm64 (Apple Silicon) | ✅      |
| Windows | x86_64                | ✅      |

## Version Support

- `latest`: Automatically installs the latest available version
- Specific versions: `25`, `24`, `23`, `22`, etc.

You can find all available versions on the [WASI SDK releases page](https://github.com/WebAssembly/wasi-sdk/releases).

## Examples

### Using Outputs

```yaml
- name: Install WASI SDK
  id: wasi-sdk
  uses: konsumer/install-wasi-sdk@v1
  with:
    version: '25'

- name: Show installation details
  run:
    |
    echo "WASI SDK installed at: ${{ steps.wasi-sdk.outputs.wasi-sdk-path }}"
    echo "WASI SDK version: ${{ steps.wasi-sdk.outputs.wasi-sdk-version }}"
    echo "Clang path: ${{ steps.wasi-sdk.outputs.clang-path }}"
    echo "Sysroot path: ${{ steps.wasi-sdk.outputs.sysroot-path }}"
```

### Building C/C++ for WebAssembly

```yaml
- name: Install WASI SDK
  uses: konsumer/install-wasi-sdk@v1

- name: Build C program
  run:
    |
    clang -o program.wasm program.c

- name: Build C++ program
  run:
    |
    clang++ -o program.wasm program.cpp -fno-exceptions
```

### Using with CMake

```yaml
- name: Install WASI SDK
  uses: konsumer/install-wasi-sdk@v1
  with:
    version: '25'

- name: Configure CMake
  run:
    |
    cmake -B build \
      -DCMAKE_TOOLCHAIN_FILE=$WASI_SDK_PATH/share/cmake/wasi-sdk.cmake \
      -DCMAKE_BUILD_TYPE=Release

- name: Build with CMake
  run: cmake --build build
```

### Matrix Build for Multiple Versions

```yaml
strategy:
  matrix:
    wasi-sdk-version:
      [
        '23',
        '24',
        '25',
      ]

steps:
  - name: Install WASI SDK
    uses: konsumer/install-wasi-sdk@v1
    with:
      version: ${{ matrix.wasi-sdk-version }}
```

## Troubleshooting

### Common Issues

1. **Download fails**: Check if the specified version exists on the [releases page](https://github.com/WebAssembly/wasi-sdk/releases)
2. **Permission denied**: Make sure the runner has write permissions to the install path
3. **Platform not supported**: Verify your runner OS and architecture are supported

### Debug Information

The action provides detailed logging. Check the action logs for:

- Platform detection results
- Download URLs
- Installation paths
- Verification results

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [WASI SDK](https://github.com/WebAssembly/wasi-sdk) - The official WASI SDK
- [wasi-libc](https://github.com/WebAssembly/wasi-libc) - WASI libc implementation
- [Wasmtime](https://github.com/bytecodealliance/wasmtime) - WebAssembly runtime
