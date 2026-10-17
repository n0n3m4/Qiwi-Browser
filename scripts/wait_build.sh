#!/bin/bash
# wait_build.sh <logfile> : block until the siso/ninja build in <logfile> ends; print summary.
LOG=$1
until grep -qE "Build Failure|Build Succeeded|build finished|The build has finished|apks/.*\.apk|^ls: cannot|^ERROR" "$LOG"; do sleep 120; done
echo "--- build ended ---"
tr '\r' '\n' < "$LOG" | grep -E "FAILED:|Build Failure|Build Succeeded|^ERROR" | sed 's/\x1b\[[0-9;]*m//g' | head -40
tr '\r' '\n' < "$LOG" | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error:|error: " | sort | uniq -c | sort -rn | head -40
