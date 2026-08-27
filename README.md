# FFmpeg macOS ARM64 Shared Builds

Automated builds of FFmpeg shared libraries (dylibs) for macOS on Apple Silicon (arm64).

Built on GitHub Actions using native Apple Silicon runners. Produces the five core
`libav*` / `libsw*` dylibs ready for bundling or runtime linking.

## Downloads

Head to [Releases](../../releases) to download pre-built archives.

Each release contains:

| Variant | Description |
|---------|-------------|
| `ffmpeg-<version>-macos-arm64-lgpl.tar.xz` | LGPL build (no x264, x265, fdk-aac) |
| `ffmpeg-<version>-macos-arm64-gpl.tar.xz`  | GPL build (includes x264, x265) |

### Included Libraries

| Library         | FFmpeg 8.x Major | Filename |
|-----------------|-------------------|----------|
| libavutil       | 60                | `libavutil.60.dylib` |
| libavcodec      | 62                | `libavcodec.62.dylib` |
| libavformat     | 62                | `libavformat.62.dylib` |
| libswscale      | 9                 | `libswscale.9.dylib` |
| libswresample   | 6                 | `libswresample.6.dylib` |

## Triggering a Build

Builds run automatically:
- **Weekly** (every Monday at 06:00 UTC)
- **On push** to `main`
- **Manually** via workflow dispatch with a configurable FFmpeg version tag

To trigger a manual build, go to Actions > Build FFmpeg > Run workflow, and enter
the desired FFmpeg git tag (e.g. `n8.1.1`, `n8.0.1`).

## Installation

### Quick Install

Download and extract:

```bash
tar -xf ffmpeg-8.1.1-macos-arm64-lgpl.tar.xz
```

The extracted directory contains:
```
lib/           # dylibs
include/       # headers (for development)
LICENSE.txt    # FFmpeg licence text
```

### Using the Install Script

An `install.sh` script is included in each archive:

```bash
# Install to a custom prefix (default: /usr/local)
./install.sh --prefix ~/ffmpeg-8

# Verify
ls ~/ffmpeg-8/lib/libavcodec.62.dylib
```

The script copies the dylibs and headers, then runs `install_name_tool` to fix
the library load paths to the target prefix.

### Adding to PATH

If your application discovers FFmpeg via PATH (e.g. the Ingestor Premiere plugin),
add the `lib/` directory:

```bash
export PATH="$HOME/ffmpeg-8/lib:$PATH"
```

Or set it system-wide in your shell profile.

## Supported Versions

This repo targets **FFmpeg 8.x** releases. The default build tag is `n8.1.1`.

Any 8.x tag can be built by specifying it in the workflow dispatch input.

## Build Configuration

### LGPL Variant

```
--enable-shared --disable-static --disable-programs
--enable-gpl=no --disable-doc
```

Codec support: built-in codecs, dav1d (AV1), libvpx, opus, svt-av1.

### GPL Variant

```
--enable-shared --disable-static --disable-programs
--enable-gpl --disable-doc
```

Additional codec support: x264, x265 (on top of everything in LGPL).

## License

The build scripts in this repository are licensed under the [MIT License](LICENSE).

FFmpeg itself is licensed under LGPL or GPL depending on configuration.
The appropriate license text is bundled with each release archive.
