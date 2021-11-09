Build Guide And Info
====================

Supported Devices
-----------------

```bash
- Asus Zenfone Max Pro M1 (X00T, XOOTD, ASUS_X00TD)
- Asus Zenfone Max Pro M2 (X01BD, X01BDA, ASUS_X01BD)
```

Default Defconfigs
------------------

```bash
- Asus Zenfone Max Pro M1 -> asus/X00TD_defconfig symlinked to X00TD_defconfig
- Asus Zenfone Max Pro M2 -> asus/X01BD_defconfig symlinked to X01BD_defconfig
```

Inline Builds(For Including Along With ROM)
-------------------------------------------

1) Make sure this [commit](https://github.com/DotOS/android_vendor_dot/commit/06e25005cd7fcec4b3c1449102d275a81a38eda1#diff-7c23235dd58c1d888df0f3a367ca789c2f562e6d04a4887fdfc8cc11ae016eec) for enabling inline kernel compilation with `newer versions` of GCC exists in `vendor/<rom>` of the source as we will be a using `GCC 12` unlike `deprecated GCC 4.9` synced from `AOSP` git, else `cherry-pick` it.
2) In your device tree, navigate to `BoardConfig` makefile
```bash
- Drop TARGET_KERNEL_CLANG_COMPILE flag
- Enable TARGET_KERNEL_NEW_GCC_COMPILE flag
```
3) Now Clone Eva GCC from [@mvaisakh](https://github.com/mvaisakh)'s github

- Trace through dependencies by adding the followong to `rom.dependencies`
```bash
  {
    "remote": "github",
    "repository": "mvaisakh/gcc-arm64",
    "target_path": "prebuilts/gcc/linux-x86/aarch64/aarch64-elf",
    "branch": "gcc-master"
  },
  {
    "remote": "github",
    "repository": "mvaisakh/gcc-arm",
    "target_path": "prebuilts/gcc/linux-x86/arm/arm-eabi",
    "branch": "gcc-master"
  }
```

- Else, just add the following to `vendorsetup.sh`
```bash
# Eva GCC
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-master prebuilts/gcc/linux-x86/aarch64/aarch64-elf
git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git -b gcc-master prebuilts/gcc/linux-x86/arm/arm-eabi
```
4) Incase you run into the following `error` during the build:-
```bash
[  2% 1811/62106] Building Kernel Image (Image.gz-dtb)
FAILED: /home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ/arch/arm64/boot/Image.gz-dtb
/bin/bash -c "(PATH=/home/workspace/citric/out/host/linux-x86/bin:\$PATH PATH=/home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-/bin:\$PATH PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/bin:\$PATH LD_LIBRARY_PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/lib:\$LD_LIBRARY_PATH PERL5LIB=/home/workspace/citric/prebuilts/tools-citric/common/perl-base BISON_PKGDATADIR=/home/workspace/citric/prebuilts/build-tools/common/bison /home/workspace/citric/prebuilts/build-tools/linux-x86/bin/make  -j8 CFLAGS_MODULE=\"-fno-pic\" CPATH=\"/usr/include:/usr/include/x86_64-linux-gnu\" HOSTCFLAGS=\"-fuse-ld=lld\" HOSTLDFLAGS=\"-L/usr/lib/x86_64-linux-gnu -L/usr/lib64 -fuse-ld=lld\" HOSTCC=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang HOSTCXX=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang++ LEX=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/flex YACC=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/bison M4=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/m4 -C kernel/asus/sdm660 O=/home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ ARCH=arm64 CROSS_COMPILE=\"/usr/bin/ccache /home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-\" CROSS_COMPILE_ARM32=\"/home/workspace/citric/prebuilts/gcc/linux-x86/arm/arm-eabi/bin/arm-eabi-\"    Image.gz-dtb ) && (if grep -q '^CONFIG_OF=y' /home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ/.config; then                   echo \"Building DTBs\";                         PATH=/home/workspace/citric/out/host/linux-x86/bin:\$PATH PATH=/home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-/bin:\$PATH PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/bin:\$PATH LD_LIBRARY_PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/lib:\$LD_LIBRARY_PATH PERL5LIB=/home/workspace/citric/prebuilts/tools-citric/common/perl-base BISON_PKGDATADIR=/home/workspace/citric/prebuilts/build-tools/common/bison /home/workspace/citric/prebuilts/build-tools/linux-x86/bin/make  -j8 CFLAGS_MODULE=\"-fno-pic\" CPATH=\"/usr/include:/usr/include/x86_64-linux-gnu\" HOSTCFLAGS=\"-fuse-ld=lld\" HOSTLDFLAGS=\"-L/usr/lib/x86_64-linux-gnu -L/usr/lib64 -fuse-ld=lld\" HOSTCC=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang HOSTCXX=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang++ LEX=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/flex YACC=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/bison M4=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/m4 -C kernel/asus/sdm660 O=/home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ ARCH=arm64 CROSS_COMPILE=\"/usr/bin/ccache /home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-\" CROSS_COMPILE_ARM32=\"/home/workspace/citric/prebuilts/gcc/linux-x86/arm/arm-eabi/bin/arm-eabi-\"    dtbs;             fi ) && (if grep -q '=m' /home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ/.config; then                         echo \"Building Kernel Modules\";                       PATH=/home/workspace/citric/out/host/linux-x86/bin:\$PATH PATH=/home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-/bin:\$PATH PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/bin:\$PATH LD_LIBRARY_PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/lib:\$LD_LIBRARY_PATH PERL5LIB=/home/workspace/citric/prebuilts/tools-citric/common/perl-base BISON_PKGDATADIR=/home/workspace/citric/prebuilts/build-tools/common/bison /home/workspace/citric/prebuilts/build-tools/linux-x86/bin/make  -j8 CFLAGS_MODULE=\"-fno-pic\" CPATH=\"/usr/include:/usr/include/x86_64-linux-gnu\" HOSTCFLAGS=\"-fuse-ld=lld\" HOSTLDFLAGS=\"-L/usr/lib/x86_64-linux-gnu -L/usr/lib64 -fuse-ld=lld\" HOSTCC=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang HOSTCXX=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang++ LEX=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/flex YACC=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/bison M4=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/m4 -C kernel/asus/sdm660 O=/home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ ARCH=arm64 CROSS_COMPILE=\"/usr/bin/ccache /home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-\" CROSS_COMPILE_ARM32=\"/home/workspace/citric/prebuilts/gcc/linux-x86/arm/arm-eabi/bin/arm-eabi-\"    modules || exit \"\$?\";                  echo \"Installing Kernel Modules\";                     PATH=/home/workspace/citric/out/host/linux-x86/bin:\$PATH PATH=/home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-/bin:\$PATH PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/bin:\$PATH LD_LIBRARY_PATH=/home/workspace/citric/prebuilts/tools-citric/linux-x86/lib:\$LD_LIBRARY_PATH PERL5LIB=/home/workspace/citric/prebuilts/tools-citric/common/perl-base BISON_PKGDATADIR=/home/workspace/citric/prebuilts/build-tools/common/bison /home/workspace/citric/prebuilts/build-tools/linux-x86/bin/make  -j8 CFLAGS_MODULE=\"-fno-pic\" CPATH=\"/usr/include:/usr/include/x86_64-linux-gnu\" HOSTCFLAGS=\"-fuse-ld=lld\" HOSTLDFLAGS=\"-L/usr/lib/x86_64-linux-gnu -L/usr/lib64 -fuse-ld=lld\" HOSTCC=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang HOSTCXX=/home/workspace/citric/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang++ LEX=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/flex YACC=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/bison M4=/home/workspace/citric/prebuilts/build-tools/linux-x86/bin/m4 -C kernel/asus/sdm660 O=/home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ ARCH=arm64 CROSS_COMPILE=\"/usr/bin/ccache /home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/aarch64-elf-\" CROSS_COMPILE_ARM32=\"/home/workspace/citric/prebuilts/gcc/linux-x86/arm/arm-eabi/bin/arm-eabi-\"    INSTALL_MOD_PATH=/home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/kernel_modules_intermediates INSTALL_MOD_STRIP=1 modules_install;                        kernel_release=\$(cat /home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ/include/config/kernel.release)                   kernel_modules_dir=/home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/kernel_modules_intermediates/lib/modules/\$kernel_release                       ;   modules=\$(find \$kernel_modules_dir -type f -name '*.ko');                      (    mkdir -p /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules ) && (cp \$modules /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules/ ) && (rm -rf /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates ) && (mkdir -p /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates/lib/modules/0.0/vendor/lib/modules ) && (cp \$modules /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates/lib/modules/0.0/vendor/lib/modules ) && (/home/workspace/citric/out/host/linux-x86/bin/depmod -b /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates 0.0 ) && (sed -e 's/\\(.*modules.*\\):/\\/\\1:/g' -e 's/ \\([^ ]*modules[^ ]*\\)/ \\/\\1/g' /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates/lib/modules/0.0/modules.dep > /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules/modules.dep ) && (cp /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates/lib/modules/0.0/modules.softdep /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules ) && (cp /home/workspace/citric/out/target/product/X01BD/obj/PACKAGING/depmod_vendor_intermediates/lib/modules/0.0/modules.alias /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules ) && (rm -f /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules/modules.load ) && (for MODULE in ; do basename \$MODULE >> /home/workspace/citric/out/target/product/X01BD/vendor/lib/modules/modules.load; done);                                      fi )"
make: Entering directory '/home/workspace/citric/kernel/asus/sdm660'
make[1]: Entering directory '/home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ'
  SLNTOLD include/config/auto.conf
  GEN     ./Makefile
  CHK     include/config/kernel.release
  GEN     ./Makefile
  CHK     include/generated/uapi/linux/version.h
  Using /home/workspace/citric/kernel/asus/sdm660 as source for kernel
  CHK     scripts/mod/devicetable-offsets.h
  CHK     include/generated/utsrelease.h
  CHK     include/generated/timeconst.h
  CHK     include/generated/bounds.h
  CHK     include/generated/asm-offsets.h
  CALL    /home/workspace/citric/kernel/asus/sdm660/scripts/checksyscalls.sh
  LD      arch/arm64/kernel/vdso/vdso.so.dbg
/home/workspace/citric/prebuilts/gcc/linux-x86/aarch64/aarch64-elf/bin/../lib/gcc/aarch64-elf/12.0.0/../../../../aarch64-elf/bin/ld: unrecognised emulation mode: aarch64linux
Supported emulations: aarch64elf aarch64elf32 aarch64elf32b aarch64elfb armelf armelfb
collect2: error: ld returned 1 exit status
make[2]: *** [/home/workspace/citric/kernel/asus/sdm660/arch/arm64/kernel/vdso/Makefile:47: arch/arm64/kernel/vdso/vdso.so.dbg] Error 1
make[1]: *** [arch/arm64/Makefile:200: vdso_prepare] Error 2
make[1]: Leaving directory '/home/workspace/citric/out/target/product/X01BD/obj/KERNEL_OBJ'
make: *** [Makefile:152: sub-make] Error 2
make: Leaving directory '/home/workspace/citric/kernel/asus/sdm660'
13:05:45 ninja failed with: exit status
```
- Then your `vendor/<rom/>` is missing this [commit](https://github.com/ArrowOS/android_vendor_arrow/commit/29fc52734526b9eaf32477196ee5013d3796bb68) which intentionally points out the `32-bit GCC Path for vdso32 compilation`. `Cherry-pick` it and the build should run without any hassle now.

Standalone Builds
-----------------

1) Clone this source into `~/Kernel` directory of your workspace.
2) Run the script as per your device
```bash
- For Asus Zenfone Max Pro M1 -> bash X00TD.sh
- For Asus Zenfone Max Pro M2 -> bash X01BD.sh
```
3) Once the builds are finished, you will find the recovery flashable zip at `~/Kernel/AnyKernel3` directory of your workspace.

Note
====

```bash
- Incase you face any bugs or errors, then create a github issue innthe repository tab with proper logs.
- Check commit history for more changelogs.
- There wont be any UC, UV variant or messed up display refresh rate variant.
- The released variants are little bit OC'ed to avoid the UI LAGS AND APP OPENING STUTTERS.
- Only Android R and S is supported. For Android Q, roms which are based on LineageOS or Android Q ports like OxygenOS and MIUI only booted.
- Dont blame the kernel if your battery charging speed isnt going up coz its you who cause it to heat already by doing heavy stuffs.
```

-----------------------------------------------------------------------------

Credits
=======

- [@ZyCromerZ](https://github.com/ZyCromerZ)
- [@Dakkshesh07](https://github.com/Dakkshesh07)
- [@RyuujiX](https://github.com/RyuujiX)
- [@Rk779](https://github.com/rk779)
- [@SonalSingh18](https://github.com/SonalSingh18)
- [@Divyanshu-Modi](https://github.com/Divyanshu-Modi)
- [@mvaisakh](https://github.com/mvaisakh)
- [@Atom-X-Devs](https://github.com/Atom-X-Devs)

<p align="center">
<img src="https://github.com/ElectroPerf/ElectroPerf-Kernel-Releases/blob/release/IMG_20210323_213350_720.png?raw=true" />
