#!/bin/bash
# Usage: scripts/build.sh [x64|arm64|x86|arm] [target]   (default: x64 chrome_public_apk)
# Env: WORK=/mnt/scratch  JOBS=<ninja jobs>
set -euo pipefail
WORK=${WORK:-/mnt/scratch}
ARCH=${1:-x64}
TARGET=${2:-chrome_public_apk}
export PATH=$WORK/depot_tools:$PATH
export DEPOT_TOOLS_UPDATE=0
ROOT=$(cd "$(dirname "$0")/.." && pwd)   # absolute: the heredoc below runs after cd
cd $WORK/chromium/src
OUT=out/$ARCH
mkdir -p $OUT
cat > $OUT/args.gn <<GN
target_os = "android"
target_cpu = "$ARCH"
is_debug = false
is_official_build = false
is_component_build = false
dcheck_always_on = false
symbol_level = 0
blink_symbol_level = 0
v8_symbol_level = 0
treat_warnings_as_errors = false
android_static_analysis = "off"
use_errorprone_java_compiler = false
disable_android_lint = true
enable_nacl = false
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
include_both_v8_snapshots = false
proprietary_codecs = true
ffmpeg_branding = "Chrome"
enable_platform_hevc = true
safe_browsing_use_unrar = false
enable_request_header_integrity = false
enable_precompiled_headers = false
cc_wrapper = "ccache"
$(cat "$ROOT/gn_args/common.gn")
GN
gn gen $OUT
autoninja -k 0 -C $OUT ${JOBS:+-j $JOBS} $TARGET
ls -la $OUT/apks/*.apk
