#!/usr/bin/env bash
# =============================================================================
# build_appimage.sh — Build Zero Browser as an AppImage
# =============================================================================
# Requirements: flutter, wget/curl, fuse (or fuse2) for running the AppImage
# Output: ZeroBrowser-x86_64.AppImage in the project root
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_ID="xyz.u00004321.ZeroBrowser"
APP_NAME="Zero Browser"
BINARY_NAME="zero_browser"
APPDIR="$SCRIPT_DIR/AppDir"
OUTPUT="$PROJECT_ROOT/ZeroBrowser-x86_64.AppImage"
APPIMAGETOOL="$SCRIPT_DIR/appimagetool-x86_64.AppImage"

echo "==> Building Flutter release bundle..."
cd "$PROJECT_ROOT"
flutter build linux --release

BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"

echo "==> Assembling AppDir structure..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$APPDIR/usr/share/$BINARY_NAME/data"

# Copy the main binary
cp "$BUNDLE_DIR/$BINARY_NAME" "$APPDIR/usr/bin/$BINARY_NAME"
chmod +x "$APPDIR/usr/bin/$BINARY_NAME"

# Copy bundled libraries
if [ -d "$BUNDLE_DIR/lib" ]; then
    cp -r "$BUNDLE_DIR/lib/." "$APPDIR/usr/lib/"
    ln -sf "../lib" "$APPDIR/usr/bin/lib"
fi

# Copy Flutter assets (data/ directory)
if [ -d "$BUNDLE_DIR/data" ]; then
    cp -r "$BUNDLE_DIR/data/." "$APPDIR/usr/share/$BINARY_NAME/data/"
fi

# Create symlink so the binary can find its data at runtime
ln -sf "../share/$BINARY_NAME/data" "$APPDIR/usr/bin/data"

# Copy icon to all required locations
cp "$SCRIPT_DIR/zero_browser.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/$APP_ID.png"
cp "$SCRIPT_DIR/zero_browser.png" "$APPDIR/.DirIcon"
cp "$SCRIPT_DIR/zero_browser.png" "$APPDIR/$APP_ID.png"

# Copy desktop entry to both locations required by AppImage spec
cp "$SCRIPT_DIR/zero_browser.desktop" "$APPDIR/usr/share/applications/$BINARY_NAME.desktop"
cp "$SCRIPT_DIR/zero_browser.desktop" "$APPDIR/$BINARY_NAME.desktop"

# Copy AppStream metainfo
mkdir -p "$APPDIR/usr/share/metainfo"
cp "$SCRIPT_DIR/$APP_ID.metainfo.xml" "$APPDIR/usr/share/metainfo/$APP_ID.metainfo.xml"

# Create AppRun launcher
cat > "$APPDIR/AppRun" << 'APPRUN_EOF'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add bundled libs to the search path
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Flutter needs to find its data directory relative to the binary.
# We symlink data/ next to the binary in AppDir/usr/bin/, so this works.
exec "$HERE/usr/bin/zero_browser" "$@"
APPRUN_EOF
chmod +x "$APPDIR/AppRun"

echo "==> Downloading appimagetool (if not already present)..."
if [ ! -f "$APPIMAGETOOL" ]; then
    wget -q --show-progress \
        "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
        -O "$APPIMAGETOOL"
    chmod +x "$APPIMAGETOOL"
fi

echo "==> Running appimagetool..."
# Use FUSE if available, otherwise extract+run (works in containers/CI)
if command -v fusermount &>/dev/null || command -v fusermount3 &>/dev/null; then
    "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"
else
    echo "    (FUSE not available, using --appimage-extract-and-run)"
    APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"
fi

echo ""
echo "✅ AppImage built successfully: $OUTPUT"
echo "   Run with: $OUTPUT"
