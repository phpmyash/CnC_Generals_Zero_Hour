#!/usr/bin/env bash
# Build a drop-in generalszh.exe for the Steam/EA copy of Zero Hour.
#
# The EA source drop in this repository cannot be compiled as-is: the DirectX,
# STLport, Miles, Bink, GameSpy and ZLib SDKs it expects are missing and the
# project files target Visual C++ 6. The community project
# TheSuperHackers/GeneralsGameCode has already solved that (CMake, VS2022,
# MinGW cross build, replacement dependencies). This script clones that project
# at a pinned commit, applies the patches kept in ../patches, and cross-compiles
# a 32-bit Windows executable on Linux.
#
# Requirements (Ubuntu/Debian):
#   sudo apt-get install g++-mingw-w64-i686 cmake make git wine64-tools libwine-dev
# (wine64-tools provides widl-stable, the IDL compiler the browser-dispatch
#  COM stub needs; libwine-dev provides the Wine IDL headers.)
#
# Usage:
#   scripts/build-zh-patched.sh [output-dir]
#
# Output:
#   <output-dir>/generalszh.exe   (default output-dir: build/zh-patched)
#
# Install: copy generalszh.exe next to generals.exe in
#   <Steam>\steamapps\common\Command and Conquer Generals - Zero Hour\
# (or the EA App equivalent) and launch generalszh.exe. The original
# generals.exe is left untouched, so you can always go back.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PATCH_DIR="$REPO_DIR/patches"
OUT_DIR="${1:-$REPO_DIR/build/zh-patched}"

FORK_URL="https://github.com/TheSuperHackers/GeneralsGameCode"
# Pinned so the patches apply cleanly. Bump deliberately and re-test.
FORK_COMMIT="2d6761cc0ff3d53a257f395ac46ef11dbcb8d865"
FORK_DIR="$REPO_DIR/build/generalsgamecode"

for tool in i686-w64-mingw32-g++ cmake make git; do
    command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
done
command -v widl >/dev/null || command -v widl-stable >/dev/null \
    || { echo "missing tool: widl (apt-get install wine64-tools libwine-dev)" >&2; exit 1; }

if [ ! -d "$FORK_DIR/.git" ]; then
    git clone "$FORK_URL" "$FORK_DIR"
fi
git -C "$FORK_DIR" fetch origin "$FORK_COMMIT" || git -C "$FORK_DIR" fetch origin
git -C "$FORK_DIR" checkout --detach "$FORK_COMMIT"
git -C "$FORK_DIR" reset --hard
git -C "$FORK_DIR" clean -fdq -e build

for p in "$PATCH_DIR"/*.patch; do
    echo "applying $(basename "$p")"
    git -C "$FORK_DIR" apply --verbose "$p"
done

cd "$FORK_DIR"
cmake --preset mingw-w64-i686 -DRTS_BUILD_GENERALS=OFF -DRTS_BUILD_CORE_TOOLS=OFF
cmake --build build/mingw-w64-i686 --target z_generals -j"$(nproc)"

mkdir -p "$OUT_DIR"
cp build/mingw-w64-i686/GeneralsMD/generalszh.exe "$OUT_DIR/"
echo
echo "Built: $OUT_DIR/generalszh.exe"
