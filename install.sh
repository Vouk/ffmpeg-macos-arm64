#!/bin/bash
#
# install.sh - Install FFmpeg shared libraries to a target prefix.
#
# Usage:
#   ./install.sh [--prefix <path>]
#
# Default prefix: /usr/local
#
# This script copies dylibs and headers to the prefix, then patches the
# dylib install names and inter-library references to point to the target
# lib/ directory using @rpath or absolute paths.
#
set -euo pipefail

PREFIX="/usr/local"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --prefix=*)
            PREFIX="${1#--prefix=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--prefix <path>]"
            echo ""
            echo "Install FFmpeg shared libraries to the given prefix."
            echo "Default prefix: /usr/local"
            echo ""
            echo "Options:"
            echo "  --prefix <path>   Installation prefix (default: /usr/local)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run '$0 --help' for usage." >&2
            exit 1
            ;;
    esac
done

# Resolve to absolute path
PREFIX="$(cd "$(dirname "$PREFIX")" 2>/dev/null && pwd)/$(basename "$PREFIX")" || PREFIX="$(mkdir -p "$PREFIX" && cd "$PREFIX" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_SRC="$SCRIPT_DIR/lib"
INC_SRC="$SCRIPT_DIR/include"

if [[ ! -d "$LIB_SRC" ]]; then
    echo "Error: lib/ directory not found next to this script." >&2
    echo "Run this script from within the extracted archive." >&2
    exit 1
fi

echo "Installing FFmpeg libraries to: $PREFIX"
echo ""

# Create target directories
mkdir -p "$PREFIX/lib"
mkdir -p "$PREFIX/include"

# Copy libraries
echo "Copying dylibs..."
cp -a "$LIB_SRC"/*.dylib "$PREFIX/lib/"

# Copy headers
if [[ -d "$INC_SRC" ]]; then
    echo "Copying headers..."
    cp -a "$INC_SRC"/* "$PREFIX/include/"
fi

# Copy licence if present
if [[ -f "$SCRIPT_DIR/LICENSE.txt" ]]; then
    cp "$SCRIPT_DIR/LICENSE.txt" "$PREFIX/"
fi

# Fix install names to use the absolute path at the target prefix
echo "Fixing dylib install names for prefix: $PREFIX/lib"
echo ""

cd "$PREFIX/lib"

# Get list of our dylibs (excluding patch-version symlinks like x.y.z.dylib)
DYLIBS=()
for f in *.dylib; do
    # Skip if it's a symlink to a more-specific version
    [[ -L "$f" ]] && continue
    DYLIBS+=("$f")
done

# Also include the major-versioned symlink targets
for f in *.dylib; do
    [[ -L "$f" ]] || continue
    TARGET="$(readlink "$f")"
    # If the symlink target is a real file in our list, skip
    # We want the actual files
done

# Rebuild: collect all real dylib files
DYLIBS=()
for f in *.dylib; do
    if [[ -f "$f" && ! -L "$f" ]]; then
        DYLIBS+=("$f")
    fi
done

echo "  Libraries: ${DYLIBS[*]}"

for dylib in "${DYLIBS[@]}"; do
    # Set the install name to the absolute path
    install_name_tool -id "$PREFIX/lib/$dylib" "$dylib" 2>/dev/null || true

    # Fix inter-library references
    while IFS= read -r line; do
        DEP_PATH="$(echo "$line" | awk '{print $1}')"
        DEP_NAME="$(basename "$DEP_PATH")"

        # Only fix references to FFmpeg's own libs
        case "$DEP_NAME" in
            libavutil*|libavcodec*|libavformat*|libswscale*|libswresample*|libavfilter*|libavdevice*|libpostproc*)
                if [[ "$DEP_PATH" != "$PREFIX/lib/$DEP_NAME" ]]; then
                    install_name_tool -change "$DEP_PATH" "$PREFIX/lib/$DEP_NAME" "$dylib" 2>/dev/null || true
                fi
                ;;
        esac
    done < <(otool -L "$dylib" | tail -n +2)
done

echo ""
echo "Done. Installed to: $PREFIX"
echo ""
echo "To use these libraries, add to your environment:"
echo "  export DYLD_LIBRARY_PATH=\"$PREFIX/lib:\$DYLD_LIBRARY_PATH\""
echo ""
echo "Or add $PREFIX/lib to your application's rpath:"
echo "  install_name_tool -add_rpath \"$PREFIX/lib\" <your_binary>"
echo ""
echo "If your app discovers FFmpeg via PATH:"
echo "  export PATH=\"$PREFIX/lib:\$PATH\""
