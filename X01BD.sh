#! /bin/bash

 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2020 Panchajanya1999 <rsk52959@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #

#Kernel building script

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR=$PWD

# The name of the device for which the kernel is built
MODEL="Asus Zenfone Max Pro M2"

# The codename of the device
DEVICE="X01BD"

# The defconfig which should be used. Get it from config.gz from
# your device or check source
DEFCONFIG=ElectroPerf_defconfig

# Show manufacturer info
MANUFACTURERINFO="ASUSTek Computer Inc."

# Specify compiler. 
# 'clang' or 'gcc'
COMPILER=clang
	if [ $COMPILER = "clang" ]
	then
		# install few necessary packages
		sudo apt-get -y install llvm lld
	fi

# Clean source prior building. 1 is NO(default) | 0 is YES
INCREMENTAL=1

# Generate a full DEFCONFIG prior building. 1 is YES | 0 is NO(default)
DEF_REG=0

# Build dtbo.img (select this only if your source has support to building dtbo.img)
# 1 is YES | 0 is NO(default)
BUILD_DTBO=0

# Sign the zipfile
# 1 is YES | 0 is NO
SIGN=0

# Debug purpose. Send logs on every successfull builds
# 1 is YES | 0 is NO(default)
LOG_DEBUG=0

##------------------------------------------------------##
##---------Do Not Touch Anything Beyond This------------##

# Check if we are using a dedicated CI ( Continuous Integration ), and
# set KBUILD_BUILD_VERSION and KBUILD_BUILD_HOST and CI_BRANCH

#Check Kernel Version
KERVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

# Set Date
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d")

#Now Its time for other stuffs like cloning, exporting, etc

 clone() {
	echo " "
	if [ $COMPILER = "clang" ]
	then
		msg "|| Cloning toolchain ||"
		git clone --depth=1 https://github.com/kdrag0n/proton-clang clang

		# Toolchain Directory defaults to clang-llvm
		TC_DIR=$KERNEL_DIR/clang
	elif [ $COMPILER = "gcc" ]
	then
		msg "|| Cloning GCC ||"
		git clone https://github.com/najahiiii/aarch64-linux-gnu.git -b linaro8-20190402 --depth=1 gcc64
		git clone https://github.com/innfinite4evr/android-prebuilts-gcc-linux-x86-arm-arm-eabi-7.2.git -b master --depth=1 gcc32
		GCC64_DIR=$KERNEL_DIR/gcc64
		GCC32_DIR=$KERNEL_DIR/gcc32
	fi

	msg "|| Cloning Anykernel ||"
        git clone https://github.com/ElectroPerf/AnyKernel3.git -b ElectroPerf-P-Wifi

	if [ $BUILD_DTBO = 1 ]
	then
		msg "|| Cloning libufdt ||"
		git clone https://android.googlesource.com/platform/system/libufdt "$KERNEL_DIR"/scripts/ufdt/libufdt
	fi
}

##------------------------------------------------------##

exports() {
	export KBUILD_BUILD_USER="ElectroPerf"
	export ARCH=arm64
	export SUBARCH=arm64

	if [ $COMPILER = "clang" ]
	then
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin/:$PATH
	elif [ $COMPILER = "gcc" ]
	then
		KBUILD_COMPILER_STRING="Linaro GCC 8.3-2019.03~dev"
		PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
	fi

	export PATH KBUILD_COMPILER_STRING
	PROCS=$(nproc --all)
	export PROCS
}

##----------------------------------------------------------##

# Function to replace defconfig versioning
setversioning() {
    # For staging branch
    KERNELNAME="ElectroPerf-4.4.262-P-WIFI-X01BD-LA.UM.9.2.r1-02700-SDMxx0.0-$DATE"
    # Export our new localversion and zipnames
    export KERNELNAME
    export ZIPNAME="$KERNELNAME.zip"
}

##--------------------------------------------------------------##

build_kernel() {
	if [ $INCREMENTAL = 0 ]
	then
		msg "|| Cleaning Sources ||"
		make clean && make mrproper && rm -rf out
	fi

	msg "|| Started Compilation ||"

	make O=out $DEFCONFIG
	if [ $DEF_REG = 1 ]
	then
		cp .config arch/arm64/configs/$DEFCONFIG
		git add arch/arm64/configs/$DEFCONFIG
		git commit -m "$DEFCONFIG: Regenerate
						This is an auto-generated commit"
	fi

	BUILD_START=$(date +"%s")
	
	if [ $COMPILER = "clang" ]
	then
		make -j"$PROCS" O=out \
				CROSS_COMPILE=aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
				CC=clang \
				AR=llvm-ar \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip
	fi

	if [ $COMPILER = "gcc" ]
	then
		export CROSS_COMPILE_ARM32=$GCC32_DIR/bin/arm-eabi-
		make -j"$PROCS" O=out CROSS_COMPILE=aarch64-linux-gnu-
	fi

	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))

	if [ -f "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb ] 
	then
		msg "|| Kernel successfully compiled ||"
	elif ! [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ]
	then
		echo -e "Kernel compilation failed, See buildlog to fix errors"
	fi

	if [ $BUILD_DTBO = 1 ]
	then
		msg "|| Building DTBO ||"
		python2 "$KERNEL_DIR/scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
			create "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" --page_size=4096 "$KERNEL_DIR/out/arch/arm64/boot/dts/qcom/sm6150-idp-overlay.dtbo"
	fi
}

##--------------------------------------------------------------##

gen_zip() {
	msg "|| Zipping into a flashable zip ||"
	mv "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
	if [ $BUILD_DTBO = 1 ]
	then
		mv "$KERNEL_DIR"/out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
	fi
	cd AnyKernel3 || exit
	cp -af "$KERNEL_DIR"/init.ElectroSpectrum.rc init.spectrum.rc && sed -i "s/persist.spectrum.kernel.*/persist.spectrum.kernel $KName/g" init.spectrum.rc
        cp -af anykernel-real.sh anykernel.sh
	zip -r9 "$ZIPNAME" * -x .git README.md anykernel-real.sh .gitignore *.zip

	## Prepare a final zip variable
	ZIP_FINAL="$ZIPNAME"

	cd ..
}

setversioning
clone
exports
build_kernel
gen_zip

##------------------------------------------------------------------##
