#!/bin/bash

# Remove all previously applied patches
cd frameworks/base
git reset --hard
git clean -f -d
git checkout .
cd ../..
cd system/bt
git checkout .
cd ../..
cd vendor/aosip
git checkout .
cd ../..
cd kernel/xiaomi/nitrogen
RESETNEEDED=`git log -1 | grep wireguard | wc -l`
if [ "$RESETNEEDED" != "0" ]
then
	RESETHASH=`git rev-parse @~`
	git reset --hard $RESETHASH
fi
cd ../../..

# Pull in upstream source changes
repo sync -f --force-sync --no-tags --no-clone-bundle
cd packages/resources/devicesettings
git pull
cd ../../..
cd packages/apps/Eleven
git pull
cd ../../..

# Patch frameworks_base
cd frameworks/base
git apply ../../device/xiaomi/nitrogen/patches/use_only_rsrp_for_lte_signal_bar.diff
git apply ../../device/xiaomi/nitrogen/patches/add_missing_frameworks_base_touch_optimization.diff
cd ../..

# Patch system_bt
cd system/bt
git apply ../../device/xiaomi/nitrogen/patches/fix_nintendo_switch_bluetooth_latency.diff
cd ../..

# Fix COMPAT_VDSO kernel compilation (as the fix hasn't landed upstream yet)
cd vendor/aosip
PATCHNEEDED=`grep -r KERNEL_CROSS_COMPILE | grep CROSS_COMPILE_ARM32 | grep androidkernel | wc -l`
if [ "$PATCHNEEDED" != "0" ]
then
	git apply ../../device/xiaomi/nitrogen/patches/fix_compat_vdso_compilation.patch
fi
cd ../..

# Patch in wireguard into the kernel
git clone https://git.zx2c4.com/android_kernel_wireguard
cd android_kernel_wireguard
./patch-kernel.sh ../kernel/xiaomi/nitrogen
cd ..
rm -rf android_kernel_wireguard

# Wipe out the package cache
rm -rf out/target/product/*/vendor 2>/dev/null
rm -rf out/target/product/*/system 2>/dev/null
rm -rf out/target/product/*/obj/PACKAGING 2>/dev/null

# Remove old builds to conserve space
rm -f out/target/product/*/*.zip*

# Build the ROM
. build/envsetup.sh
lunch aosip_nitrogen-userdebug
time mka kronic
