#!/bin/bash
# Release-tier arm64 build: official build (ThinLTO, PGO from the arm64 orderfile package, R8 full-mode,
# resource allowlisting), signed with release/release.keystore when present.
# Usage: scripts/build_release.sh [target]   (default chrome_public_apk)   Env: WORK=/mnt/scratch JOBS=<n>
# Output: $WORK/chromium/src/out/arm64-release/apks/ChromePublic.apk
set -euo pipefail
WORK=${WORK:-/mnt/scratch}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TARGET=${1:-chrome_public_apk}
export PATH=$WORK/depot_tools:$PATH
export DEPOT_TOOLS_UPDATE=0
cd $WORK/chromium/src
OUT=out/arm64-release
mkdir -p $OUT

# PGO profile ships in the cipd package chrome/android/orderfiles/arm64 (pulled by gclient sync).
[ -f chrome/android/orderfiles/arm64/pgo_profile.arm64.profdata ] || { echo "missing arm64 PGO profile"; exit 1; }
# V8 builtins PGO (official builds): gclient's checkout_v8_builtins_pgo_profiles hook is off in a plain
# checkout, so fetch the profiles for the checked-out V8 version once (x64 profile is used for arm64 too).
[ -f v8/tools/builtins-pgo/profiles/x64.profile ] || \
  python3 v8/tools/builtins-pgo/download_profiles.py download --depot-tools $WORK/depot_tools

KEYSTORE_ARGS=""
if [ -f $ROOT/release/release.keystore ] && [ -f $ROOT/release/keystore.password ]; then
  KEYSTORE_ARGS="android_keystore_path = \"$ROOT/release/release.keystore\"
android_keystore_name = \"release\"
android_keystore_password = \"$(cat $ROOT/release/keystore.password)\""
else
  echo "WARNING: release/release.keystore not found, APK will be signed with Chromium's public debug key"
fi

cat > $OUT/args.gn <<GN
# --- release (mirrors cromite's build/cromite.gn_args + chromium.gn_args for Android arm64) ---
target_os = "android"
target_cpu = "arm64"
is_official_build = true
is_debug = false
is_component_build = false
dcheck_always_on = false
debuggable_apks = false
is_high_end_android = true
chrome_pgo_phase = 2
symbol_level = 0
blink_symbol_level = 0
v8_symbol_level = 0
generate_linker_map = false
include_both_v8_snapshots = false
include_both_v8_snapshots_android_secondary_abi = false
# --- same feature set as the dev build (scripts/build.sh) ---
treat_warnings_as_errors = false
android_static_analysis = "off"
use_errorprone_java_compiler = false
disable_android_lint = true
enable_remoting = false
enable_vr = false
enable_arcore = false
enable_openxr = false
enable_cardboard = false
enable_reporting = false
enable_mdns = false
enable_hangout_services_extension = false
use_official_google_api_keys = false
disable_fieldtrial_testing_config = true
proprietary_codecs = true
ffmpeg_branding = "Chrome"
enable_platform_hevc = true
enable_platform_dolby_vision = false
enable_platform_encrypted_dolby_vision = false
media_use_openh264 = false
safe_browsing_use_unrar = false
enable_request_header_integrity = false
enable_precompiled_headers = false
build_tflite_with_xnnpack = false
build_litert_with_xnnpack = false
cc_wrapper = "ccache"
$KEYSTORE_ARGS
$(cat "$ROOT/gn_args/common.gn" 2>/dev/null || true)
GN
gn gen $OUT --fail-on-unused-args
[ -n "${GN_ONLY:-}" ] && { echo "gn gen ok (GN_ONLY)"; exit 0; }
autoninja -k 0 -C $OUT ${JOBS:+-j $JOBS} $TARGET
ls -la $OUT/apks/*.apk
