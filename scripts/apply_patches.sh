#!/bin/bash
# Apply all patch sets in order onto a clean Chromium checkout (see scripts/checkout.sh).
# Each patches/NN-name/ dir has a `series` file listing patch files in apply order.
set -euo pipefail
WORK=${WORK:-/mnt/scratch}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd $WORK/chromium/src
git am --abort 2>/dev/null || true
for dir in $(ls -d $ROOT/patches/*/ | sort); do
  [ -f $dir/series ] || continue
  while read -r p; do
    [ -z "$p" ] && continue; [[ "$p" == \#* ]] && continue
    echo "==> $(basename $dir)/$p"
    if ! git am -3 --keep-cr --no-gpg-sign "$dir/$p" 2>/dev/null; then
      git am --abort 2>/dev/null || true
      git apply -3 --index "$dir/$p"
      git -c user.name=build -c user.email=build@localhost commit -q -m "$(basename $dir): $p"
    fi
  done < $dir/series
done
echo PATCHES_DONE
