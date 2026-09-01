# FFmpeg macOS ARM64 Shared Builds

Automated builds of FFmpeg shared libraries (dylibs) for macOS on Apple Silicon (arm64).

Built on GitHub Actions using native Apple Silicon runners. Produces the five core
`libav*` / `libsw*` dylibs ready for bundling or runtime linking.

## Downloads

Head to [Releases](../../releases) to download pre-built installer packages.

Each release contains:

| Variant | Description |
|---------|-------------|
| `ffmpeg-<version>-macos-arm64-lgpl.pkg` | LGPL build (no x264, x265, fdk-aac) |
| `ffmpeg-<version>-macos-arm64-gpl.pkg`  | GPL build (includes x264, x265) |

Packages are signed with a Developer ID Installer certificate and notarized +
stapled by Apple (when signing secrets are configured on the repository), so
they install without Gatekeeper warnings.

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

## Signing & Notarization Setup

To produce signed and notarized packages, configure these repository secrets
(Settings > Secrets and variables > Actions). If they are absent, the workflow
still builds an **unsigned** `.pkg` so forks and PRs keep working.

### Certificate (required for signing)

Export a single `.p12` containing **both** your *Developer ID Application* and
*Developer ID Installer* certificates (with their private keys), then base64
encode it.

| Secret | Description |
|--------|-------------|
| `MACOS_CERT_P12_BASE64` | Base64 of the `.p12` bundle. `base64 -i certs.p12 \| pbcopy` |
| `MACOS_CERT_PASSWORD`   | Password protecting the `.p12` |

### Notarization credentials (required for notarize + staple)

Use **either** the App Store Connect API key (preferred) **or** an Apple ID +
app-specific password. If only the certificate secrets are set, packages are
signed but not notarized.

App Store Connect API key:

| Secret | Description |
|--------|-------------|
| `APPLE_API_KEY_ID`     | Key ID of the App Store Connect API key |
| `APPLE_API_ISSUER_ID`  | Issuer ID for the key |
| `APPLE_API_KEY_BASE64` | Base64 of the `AuthKey_XXXX.p8` file |

Apple ID fallback:

| Secret | Description |
|--------|-------------|
| `APPLE_ID`          | Apple developer account email |
| `APPLE_ID_PASSWORD` | App-specific password for that Apple ID |

The Team ID is derived automatically from the Developer ID Application identity.

## Installation

Download the `.pkg` for the variant you want and either double-click it in
Finder or install from the command line:

```bash
sudo installer -pkg ffmpeg-8.1.1-macos-arm64-lgpl.pkg -target /
```

The package installs into `/usr/local`:

```
/usr/local/lib/       # dylibs (install names set to /usr/local/lib/<lib>)
/usr/local/include/   # headers (for development)
/usr/local/share/ffmpeg-macos-arm64/<pkg>/LICENSE.txt
```

Because the dylib install names are absolute (`/usr/local/lib/<lib>`), anything
that links against them resolves the libraries automatically once installed.

### Verifying the signature

```bash
# Check the installer signature and notarization
pkgutil --check-signature ffmpeg-8.1.1-macos-arm64-lgpl.pkg
spctl --assess --type install --verbose=2 ffmpeg-8.1.1-macos-arm64-lgpl.pkg
```

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
The appropriate license text is bundled inside each installer package
(installed to `/usr/local/share/ffmpeg-macos-arm64/<pkg>/LICENSE.txt`).
