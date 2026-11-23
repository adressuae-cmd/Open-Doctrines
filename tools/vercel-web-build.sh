#!/usr/bin/env bash
# Builds the ACTUAL OpenDoctrines game with the current source changes to WebAssembly.
# This is deployment plumbing only. Game source, economics, UI and translations are untouched.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# Installed for this deployment only; no modifications to the game source.
emsdk_home="${HOME}/.cache/opendoctrines-emsdk"
if [ ! -d "$emsdk_home/.git" ]; then
  mkdir -p "$(dirname "$emsdk_home")"
  git clone -q --depth 1 https://github.com/emscripten-core/emsdk.git "$emsdk_home"
fi
"$emsdk_home/emsdk" install latest
"$emsdk_home/emsdk" activate latest
# shellcheck disable=SC1090
source "$emsdk_home/emsdk_env.sh"

python3 -m pip install --user fonttools || echo "Optional fonttools unavailable; continuing"
emcmake cmake -S . -B build-web -DCMAKE_BUILD_TYPE=Release -DOD_WEB_MAXIMUM_MEMORY=2GB
emmake cmake --build build-web --target OpenDoctrines -j 4

mkdir -p site
for file in index.html OpenDoctrines.js OpenDoctrines.wasm OpenDoctrines.data; do
  test -s "build-web/$file"
  cp "build-web/$file" "site/$file"
done
if [ -f build-web/icon.png ]; then cp build-web/icon.png site/; fi
test -d build-web/data/STDmaps
cp -a build-web/data site/
touch site/.nojekyll
echo "Playable OpenDoctrines website built from commit ${VERCEL_GIT_COMMIT_SHA:-unknown}"
du -sh site
