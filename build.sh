#!/bin/bash
# Accent Picker — build script for macOS
#
#   bash build.sh            → builds "build/Accent Picker.app"
#   bash build.sh --install  → builds it, installs it into /Applications and opens it
#   bash build.sh --release  → builds a zip to attach to a GitHub release
#                              (Universal when your SDK can still build for Intel)
#
# Signing for other people's Macs (optional, needs a paid Apple Developer account):
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="accent-picker" bash build.sh --release
# Without these, the release is signed locally and users click "Open Anyway" once.
#
# Written for the bash 3.2 that ships with macOS: every variable is in braces.
set -eo pipefail
cd "$(dirname "$0")"

NAME="AccentPicker"                 # executable name
DISPLAY_NAME="Accent Picker"        # app name shown in Finder, the Dock and the menu bar
VERSION="1.0.0"
AUTHOR="Lucas Aymard"
APP="build/${DISPLAY_NAME}.app"
DEST="/Applications/${DISPLAY_NAME}.app"

trap 'printf "\n\033[1;31m✖ Stopped at line %s of build.sh. Send me everything above.\033[0m\n" "${LINENO}"' ERR
say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m✖ %s\033[0m\n' "$*"; exit 1; }

MODE="build"
case "${1:-}" in
  --install) MODE="install" ;;
  --release) MODE="release" ;;
  "") ;;
  *) fail "Unknown option ${1}. Use --install, --release or nothing." ;;
esac
STEPS=3
if [ "${MODE}" != "build" ]; then STEPS=4; fi

# 1 ─ checks
say "1/${STEPS}  Checking the tools"
[ -f Resources/AppIcon.icns ] || fail "Resources/AppIcon.icns is missing. Unzip the whole AccentPicker folder again."
[ -f Package.swift ] || fail "Package.swift not found in $(pwd). Unzip the whole AccentPicker folder and run this from inside it."
if ! xcrun --find swift >/dev/null 2>&1; then
  xcode-select --install 2>/dev/null || true
  fail "The Xcode tools are missing. Finish the install window that just opened, then run this command again."
fi
echo "   $(xcrun swift --version 2>/dev/null | head -n 1)"

# 2 ─ compile
say "2/${STEPS}  Compiling (the first time takes a minute)"
# Same build as --install (proven to work), for this Mac's chip.
if ! xcrun swift build -c release; then
  fail "Compilation failed. Send me the lines above, starting with the first 'error:'."
fi
BIN="$(xcrun swift build -c release --show-bin-path)/${NAME}"
[ -f "${BIN}" ] || fail "The compiled binary was not found at ${BIN}."

if [ "${MODE}" = "release" ]; then
  # Try to add an Intel version too. If the SDK can't, the release is Apple silicon only.
  # Keep a copy first: the Intel build may write to the same output folder.
  mkdir -p build
  cp "${BIN}" "build/${NAME}-native"
  BIN="build/${NAME}-native"
  ARCHS="Apple silicon only"
  echo "   Trying to add an Intel version (optional)…"
  if xcrun swift build -c release --arch x86_64 >/dev/null 2>&1; then
    X86_BIN=""
    for f in $(find .build -type f -name "${NAME}" -not -path "*.dSYM*" 2>/dev/null); do
      if lipo -archs "${f}" 2>/dev/null | grep -qw x86_64; then X86_BIN="${f}"; fi
    done
    if [ -n "${X86_BIN}" ] && lipo -archs "${BIN}" 2>/dev/null | grep -qw arm64; then
      if lipo -create "${BIN}" "${X86_BIN}" -output "build/${NAME}-universal" 2>/dev/null; then
        BIN="build/${NAME}-universal"
        ARCHS="Universal (Apple silicon + Intel)"
      fi
    fi
  fi
  echo "   ${ARCHS}"
fi
[ -f "${BIN}" ] || fail "The compiled binary was not found at ${BIN}."

# 3 ─ app bundle
say "3/${STEPS}  Building ${DISPLAY_NAME}.app"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "${BIN}" "${APP}/Contents/MacOS/${NAME}"
cp Resources/AppIcon.icns "${APP}/Contents/Resources/AppIcon.icns"

cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${DISPLAY_NAME}</string>
    <key>CFBundleDisplayName</key><string>${DISPLAY_NAME}</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>NSHumanReadableCopyright</key><string>© 2026 ${AUTHOR}</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundleIdentifier</key><string>io.github.lucasaym.AccentPicker</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

SIGN_ID="${DEVELOPER_ID:-}"
if [ "${MODE}" = "release" ] && [ -n "${SIGN_ID}" ]; then
  # Developer ID + hardened runtime: required for Apple notarization.
  codesign --force --options runtime --timestamp --sign "${SIGN_ID}" "${APP}" \
    || fail "Signing with \"${SIGN_ID}\" failed. Check the name with: security find-identity -v -p codesigning"
  SIGNED="developer"
else
  # Local (ad-hoc) signature: enough for your own Mac.
  codesign --force --sign - "${APP}" >/dev/null 2>&1 || fail "Signing the app failed."
  SIGNED="adhoc"
fi
echo "   ${APP}"

if [ "${MODE}" = "build" ]; then
  say "Done ✔  The app is in $(pwd)/${APP}"
  exit 0
fi

if [ "${MODE}" = "release" ]; then
  say "4/${STEPS}  Zipping for GitHub"
  ZIP="build/Accent-Picker-${VERSION}-macOS.zip"
  rm -f "${ZIP}"
  ditto -c -k --sequesterRsrc --keepParent "${APP}" "${ZIP}"
  if [ "${SIGNED}" = "developer" ] && [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "   Sending to Apple for notarization (usually a few minutes)…"
    NOTARY_OUT="$(xcrun notarytool submit "${ZIP}" --keychain-profile "${NOTARY_PROFILE}" --wait 2>&1 || true)"
    echo "${NOTARY_OUT}" | sed 's/^/   /'
    echo "${NOTARY_OUT}" | grep -q "status: Accepted" || fail "Notarization was not accepted (see above)."
    xcrun stapler staple "${APP}" >/dev/null || fail "Stapling the notarization ticket failed."
    rm -f "${ZIP}"
    ditto -c -k --sequesterRsrc --keepParent "${APP}" "${ZIP}"
    TRUST="Signed and notarized: opens on any Mac with no warning."
  elif [ "${SIGNED}" = "developer" ]; then
    TRUST="Signed but not notarized: set NOTARY_PROFILE to notarize it."
  else
    TRUST="Not notarized: people will click \"Open Anyway\" once (see README)."
  fi
  say "Done ✔  ${ZIP}"
  echo "   ${ARCHS}"
  echo "   ${TRUST}"
  echo "   Attach this zip to a new release on GitHub (Releases › Draft a new release)."
  exit 0
fi

# 4 ─ install
say "4/${STEPS}  Installing into /Applications"
pkill -x "${NAME}" 2>/dev/null || true
sleep 0.5
rm -rf "${DEST}" "/Applications/${NAME}.app"   # also removes the old "AccentPicker.app"
ditto "${APP}" "${DEST}"
touch "${DEST}"   # makes Finder pick up the new icon
xattr -dr com.apple.quarantine "${DEST}" 2>/dev/null || true
open "${DEST}"

say "Done ✔  Installed in ${DEST}"
