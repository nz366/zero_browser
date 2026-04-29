#!/usr/bin/env bash
# =============================================================================
# build_flatpak.sh — Build and install Zero Browser as a Flatpak
# =============================================================================
# Requirements: flatpak, flatpak-builder (auto-installed if missing via flatpak)
# Output: ZeroBrowser.flatpak bundle in the project root
#         AND a user-scoped Flatpak install (run with: flatpak run xyz.u00004321.ZeroBrowser)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_ID="xyz.u00004321.ZeroBrowser"
MANIFEST="$SCRIPT_DIR/$APP_ID.yml"
BUILD_DIR="$SCRIPT_DIR/.flatpak-build"
REPO_DIR="$SCRIPT_DIR/.flatpak-repo"
OUTPUT="$PROJECT_ROOT/ZeroBrowser.flatpak"

# ---------------------------------------------------------------------------
# 1. Ensure flatpak-builder is available
# ---------------------------------------------------------------------------
if ! command -v flatpak-builder &>/dev/null; then
    echo "==> flatpak-builder not found. Attempting to install via flatpak..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y flatpak-builder
    elif command -v flatpak &>/dev/null; then
        # Some distros ship flatpak-builder as a flatpak extension
        flatpak install --user -y flathub org.flatpak.Builder || true
        # Alias if installed as flatpak
        if flatpak list --user | grep -q "org.flatpak.Builder"; then
            flatpak_builder_cmd="flatpak run org.flatpak.Builder"
        else
            echo "ERROR: Could not install flatpak-builder. Please install it manually:"
            echo "  Ubuntu/Debian: sudo apt install flatpak-builder"
            echo "  Fedora:        sudo dnf install flatpak-builder"
            exit 1
        fi
    else
        echo "ERROR: Neither apt-get nor flatpak found. Install flatpak-builder manually."
        exit 1
    fi
fi

FLATPAK_BUILDER="${flatpak_builder_cmd:-flatpak-builder}"

# ---------------------------------------------------------------------------
# 2. Ensure required Flatpak runtimes are installed
# ---------------------------------------------------------------------------
echo "==> Ensuring Flatpak runtimes are available..."
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak install --user -y flathub org.freedesktop.Platform//24.08 2>/dev/null || true
flatpak install --user -y flathub org.freedesktop.Sdk//24.08 2>/dev/null || true

# ---------------------------------------------------------------------------
# 3. Build Flutter release bundle
# ---------------------------------------------------------------------------
echo "==> Building Flutter release bundle..."
cd "$PROJECT_ROOT"
flutter build linux --release

# ---------------------------------------------------------------------------
# 4. Build the Flatpak
# ---------------------------------------------------------------------------
echo "==> Building Flatpak with flatpak-builder..."
rm -rf "$BUILD_DIR"

$FLATPAK_BUILDER \
    --force-clean \
    --user \
    --install \
    --repo="$REPO_DIR" \
    "$BUILD_DIR" \
    "$MANIFEST"

# ---------------------------------------------------------------------------
# 5. Export a portable .flatpak bundle
# ---------------------------------------------------------------------------
echo "==> Exporting .flatpak bundle..."
flatpak build-bundle \
    --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
    "$REPO_DIR" \
    "$OUTPUT" \
    "$APP_ID"

echo ""
echo "✅ Flatpak built successfully!"
echo "   Bundle:       $OUTPUT"
echo "   Run directly: flatpak run $APP_ID"
echo ""
echo "   To install the bundle on another machine:"
echo "     flatpak install --user $OUTPUT"
