#!/bin/bash
# Shallow checkout of Chromium at the pinned tag (same method as cromite's prepare-build.sh).
set -euo pipefail
WORK=${WORK:-/mnt/scratch}
VERSION=$(cat "$(dirname "$0")/../CHROMIUM_VERSION")
CHR_SOURCE=https://chromium.googlesource.com/chromium/src.git

export PATH=$WORK/depot_tools:$PATH
export DEPOT_TOOLS_UPDATE=0
[ -d $WORK/depot_tools ] || git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $WORK/depot_tools
$WORK/depot_tools/ensure_bootstrap

mkdir -p $WORK/chromium/src && cd $WORK/chromium/src
if [ ! -d .git ]; then
  git init
  git remote add origin $CHR_SOURCE
  git config --unset-all remote.origin.fetch || true
  git config --add remote.origin.fetch "+refs/tags/${VERSION}:refs/tags/${VERSION}"
  git fetch --depth 2 $CHR_SOURCE +refs/tags/$VERSION:chromium_$VERSION
  git checkout $VERSION
  git config user.email "build@localhost"; git config user.name "build"
fi
VERSION_SHA=$(git show-ref -s $VERSION | head -n1)

cat >../.gclient <<GC
solutions = [
  { "name": 'src',
    "url": '$CHR_SOURCE@$VERSION_SHA',
    "deps_file": 'DEPS',
    "managed": False,
    "custom_deps": {
        "src/third_party/gperf": None,
        "src/third_party/lighttpd": None,
        "src/third_party/perl": None,
        "src/third_party/screen-ai/windows_amd64": None,
        "src/third_party/screen-ai/windows_386": None,
        "src/third_party/cronet_android_mainline_clang/linux-amd64": None,
        "src/testing/libfuzzer/fuzzers/wasm_corpus": None,
    },
    "custom_vars": {
       "checkout_android_prebuilts_build_tools": True,
       "checkout_telemetry_dependencies": False,
       "checkout_pgo_profiles": False,
    },
  },
]
target_os=['android']
GC
git submodule foreach git config -f ./.git/config submodule.\$name.ignore all || true
gclient sync -D --no-history --nohooks
gclient runhooks
rm -rf third_party/angle/third_party/VK-GL-CTS/
echo CHECKOUT_DONE
