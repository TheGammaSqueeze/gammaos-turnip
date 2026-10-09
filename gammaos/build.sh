#!/bin/bash
# Builds Turnip (Mesa freedreno Vulkan, KGSL) for Android arm64 and packages it as an
# adrenotools driver zip (meta.json + vulkan.gammaos.so) for azahar-nano / drastic-nano.
# Usage: gammaos/build.sh [ndk dir]   (default /work/android-ndk-r27c)
set -e
cd "$(dirname "$0")/.."
NDK=${1:-${ANDROID_NDK:-/work/android-ndk-r27c}}
OUT=gammaos/out
mkdir -p $OUT
sed "s|@NDK@|$NDK|g" gammaos/android-aarch64.ini > $OUT/cross.ini
if [ ! -f $OUT/build/build.ninja ]; then
  meson setup $OUT/build --cross-file $OUT/cross.ini \
    -Dbuildtype=release -Db_lto=false -Dstrip=true \
    -Dplatforms=android -Dplatform-sdk-version=30 -Dandroid-stub=true -Dandroid-strict=false \
    -Dgallium-drivers= -Dvulkan-drivers=freedreno -Dfreedreno-kmds=kgsl \
    -Dvulkan-beta=true -Dshared-glapi=disabled -Dgles1=disabled -Dgles2=disabled \
    -Dopengl=false -Dglx=disabled -Degl=disabled -Dllvm=disabled \
    -Dzstd=disabled -Dvalgrind=disabled -Dbuild-tests=false
fi
ninja -C $OUT/build src/freedreno/vulkan/libvulkan_freedreno.so
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REV=$(git rev-parse --short=10 HEAD)
VER=$(cat VERSION)
PKG=$OUT/pkg
rm -rf $PKG && mkdir -p $PKG
cp $OUT/build/src/freedreno/vulkan/libvulkan_freedreno.so $PKG/vulkan.gammaos.so
cat > $PKG/meta.json <<J
{
  "schemaVersion": 1,
  "name": "GammaOS Turnip $BRANCH $REV",
  "description": "Turnip (Mesa $VER) built from github.com/TheGammaSqueeze/gammaos-turnip branch $BRANCH, commit $REV",
  "author": "TheGammaSqueeze",
  "packageVersion": "$REV",
  "vendor": "Mesa",
  "driverVersion": "$VER-$BRANCH-$REV",
  "minApi": 30,
  "libraryName": "vulkan.gammaos.so"
}
J
(cd $PKG && rm -f ../gammaos-turnip-$BRANCH-$REV.zip && zip -q ../gammaos-turnip-$BRANCH-$REV.zip meta.json vulkan.gammaos.so)
ls -la $OUT/gammaos-turnip-$BRANCH-$REV.zip
