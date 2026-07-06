#!/bin/bash
# Batch-verify the CCQN v2 patch: unpack, patch, and build `make std`
# for every VASP tarball found in a directory.
#
# Usage:
#   ./build_all_vasp_ccqn.sh <tarball_dir> <patch_file> <makefile.include> [make_jobs]
#
# Example (sai, Intel oneAPI):
#   module load intel-oneapi   # or however the toolchain is provided
#   ./build_all_vasp_ccqn.sh ~/vasp-tarballs ./vasp_ccqn.patch \
#       ~/vasp-build/makefile.include.intel 16
#
# Each build runs in ./ccqn_build/<version>/ with its log in build.log.
# A summary table is printed at the end. Safe to re-run: existing build
# directories are removed first.

set -u

TARDIR=${1:?tarball directory}
PATCHF=$(readlink -f "${2:?patch file}")
MKINC=$(readlink -f "${3:?makefile.include}")
JOBS=${4:-8}

WORK=$PWD/ccqn_build
mkdir -p "$WORK"

declare -a RESULT

for tb in "$TARDIR"/vasp.6.*.t*gz; do
    [ -e "$tb" ] || { echo "no tarballs found in $TARDIR"; exit 1; }
    name=$(basename "$tb")
    ver=$(echo "$name" | sed -E 's/^vasp\.([0-9.]+[0-9])\..*/\1/')
    bdir="$WORK/$ver"
    echo "=== $ver ($name)"
    rm -rf "$bdir"
    mkdir -p "$bdir"

    tar -xzf "$tb" -C "$bdir" || { RESULT+=("$ver UNPACK_FAIL"); continue; }

    # 6.2.1 ships as a nested tarball
    inner=$(find "$bdir" -maxdepth 2 -name 'vasp.6*.tgz' | head -1)
    if [ -n "$inner" ]; then
        tar -xzf "$inner" -C "$bdir" || { RESULT+=("$ver UNPACK_FAIL"); continue; }
    fi

    src=$(find "$bdir" -maxdepth 2 -name .objects -path '*/src/*' | head -1)
    root=$(dirname "$(dirname "$src")")
    if [ -z "$src" ]; then RESULT+=("$ver NO_SRC"); continue; fi

    ( cd "$root" && patch -p1 --fuzz=1 --ignore-whitespace < "$PATCHF" ) \
        > "$bdir/patch.log" 2>&1
    if grep -qiE 'FAILED|rej' "$bdir/patch.log"; then
        RESULT+=("$ver PATCH_FAIL")
        continue
    fi

    cp "$MKINC" "$root/makefile.include"
    echo "    building (make -j$JOBS std) ... log: $bdir/build.log"
    ( cd "$root" && make -j"$JOBS" std ) > "$bdir/build.log" 2>&1
    if [ -x "$root/bin/vasp_std" ]; then
        RESULT+=("$ver OK")
    else
        RESULT+=("$ver BUILD_FAIL")
    fi
done

echo
echo "================ summary ================"
printf '%s\n' "${RESULT[@]}" | column -t
echo "========================================="
fails=$(printf '%s\n' "${RESULT[@]}" | grep -cv ' OK$')
exit "$fails"
