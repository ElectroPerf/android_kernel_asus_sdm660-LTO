#! /bin/bash
# shellcheck disable=SC2154

 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2021 Panchajanya1999 <rsk52959@gmail.com>
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
	echo
    echo -e "\e[1;32m$*\e[0m"
    echo
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR=$HOME/Kernel
cd $KERNEL_DIR

# The name of the device for which the kernel is built
MODEL="Asus Zenfone Max Pro M2"

# The codename of the device
DEVICE="X01BD"

# The defconfig which should be used. Get it from config.gz from
# your device or check source
DEFCONFIG=asus/X01BD_defconfig

# Show manufacturer info
MANUFACTURERINFO="ASUSTek Computer Inc."

# Kernel Variant
VARIANT=P-WIFI

# Build Type
BUILD_TYPE="TEST: Might be unstable so use at your own risk"

# Specify compiler.
# 'clang' or 'clangxgcc' or 'gcc'
COMPILER=gcc

# Kernel is LTO
LTO=1

# Specify linker.
# 'ld.lld'(default)
LINKER=ld.lld

# Clean source prior building. 1 is NO(default) | 0 is YES
INCREMENTAL=1

# Push ZIP to Telegram. 1 is YES | 0 is NO(default)
PTTG=1
	if [ $PTTG = 1 ]
	then
		# Set Telegram Chat ID
		CHATID="-1001158889781"
	fi

# Generate a full DEFCONFIG prior building. 1 is YES | 0 is NO(default)
DEF_REG=0

# Files/artifacts
FILES=Image.gz-dtb

# Build dtbo.img (select this only if your source has support to building dtbo.img)
# 1 is YES | 0 is NO(default)
BUILD_DTBO=0

# Sign the zipfile
# 1 is YES | 0 is NO
SIGN=0
	if [ $SIGN = 1 ]
	then
		#Check for java
		if command -v java > /dev/null 2>&1; then
			SIGN=1
		else
			SIGN=0
		fi
	fi

# Silence the compilation
# 1 is YES(default) | 0 is NO
SILENCE=0

# Debug purpose. Send logs on every successfull builds
# 1 is YES | 0 is NO(default)
LOG_DEBUG=0

##------------------------------------------------------##
##---------Do Not Touch Anything Beyond This------------##

# Check if we are using a dedicated CI ( Continuous Integration ), and
# set KBUILD_BUILD_VERSION and KBUILD_BUILD_HOST and CI_BRANCH

## Set defaults first
CI=DRONE
DISTRO=$(cat /etc/issue)
KBUILD_BUILD_HOST=$(uname -a | awk '{print $2}')
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TERM=xterm
export KBUILD_BUILD_HOST CI_BRANCH TERM

## Check for CI
	if [ $CI = "CIRCLECI" ]
	then
		export KBUILD_BUILD_VERSION=$CIRCLE_BUILD_NUM
		export KBUILD_BUILD_HOST="CircleCI"
		export CI_BRANCH=$CIRCLE_BRANCH
	
	elif [ $CI = "DRONE" ]
	then
		export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
		export KBUILD_BUILD_HOST=$DRONE_SYSTEM_HOST
		export CI_BRANCH=$DRONE_BRANCH
		export BASEDIR=$DRONE_REPO_NAME # overriding
		export SERVER_URL="https://cloud.drone.io/ElectroPerf/${DRONE_REPO_NAME}/${KBUILD_BUILD_VERSION}/1/2"
	fi

#Check Kernel Version
LINUXVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

# Set Date
DATE=$(TZ=Asia/Kolkata date +"%Y-%m-%d")

#Now Its time for other stuffs like cloning, exporting, etc

 clone() {
	echo " "
	if [ $COMPILER = "clang" ]
	then
		msg "|| Cloning toolchain ||"
		git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git $KERNEL_DIR/clang

	elif [ $COMPILER = "clangxgcc" ]
	then
		msg "|| Cloning toolchain ||"
		git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git $KERNEL_DIR/clang

		msg "|| Cloning GCC 12.0.0 Bare Metal ||"
		git clone https://github.com/mvaisakh/gcc-arm64.git $KERNEL_DIR/gcc64 --depth=1
                git clone https://github.com/mvaisakh/gcc-arm.git $KERNEL_DIR/gcc32 --depth=1

	elif [ $COMPILER = "gcc" ]
	then
		msg "|| Cloning GCC Bare Metal ||"
		git clone https://github.com/mvaisakh/gcc-arm64.git $KERNEL_DIR/gcc64 --depth=1
		git clone https://github.com/mvaisakh/gcc-arm.git $KERNEL_DIR/gcc32 --depth=1
	fi

	# Toolchain Directory defaults to clang-llvm
		TC_DIR=$KERNEL_DIR/clang

	# GCC Directory
		GCC64_DIR=$KERNEL_DIR/gcc64
		GCC32_DIR=$KERNEL_DIR/gcc32

	# AnyKernel Directory
		AK_DIR=$KERNEL_DIR/Anykernel3

	msg "|| Cloning Anykernel ||"
        git clone https://github.com/ElectroPerf/AnyKernel3-X01BD.git -b ElectroPerf-P-Wifi $KERNEL_DIR/Anykernel3

	if [ $BUILD_DTBO = 1 ]
	then
		msg "|| Cloning libufdt ||"
		git clone https://android.googlesource.com/platform/system/libufdt $KERNEL_DIR/scripts/ufdt/libufdt
	fi
}

##----------------------------------------------------------##

# Function to replace defconfig versioning
setversioning() {
    # For staging branch
    KERNELNAME="ElectroPerf-$LINUXVER-LTO-$VARIANT-X01BD-$(TZ=Asia/Kolkata date +"%Y-%m-%d-%s")"
    # Export our new localversion and zipnames
    export KERNELNAME
    export ZIPNAME="$KERNELNAME.zip"
}

##--------------------------------------------------------------##

exports() {
	export KBUILD_BUILD_USER="ElectroPerf"
	export ARCH=arm64
	export SUBARCH=arm64

	if [ $COMPILER = "clang" ]
	then
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin/:$PATH
	elif [ $COMPILER = "clangxgcc" ]
	then
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:/usr/bin:$PATH
	elif [ $COMPILER = "gcc" ]
	then
		KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-elf-gcc --version | head -n 1)
		PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
	fi

	if [ $LTO = "1" ];then
		export LD=ld.lld
	fi

	export PATH KBUILD_COMPILER_STRING
	PROCS=$(nproc)
	export PROCS

	BOT_MSG_URL="https://api.telegram.org/bot$TOKEN/sendMessage"
	BOT_BUILD_URL="https://api.telegram.org/bot$TOKEN/sendDocument"
	PROCS=$(nproc)

    if [ -e $GCC64_DIR/bin/aarch64-elf-gcc ];then
        gcc64Type="$($GCC64_DIR/bin/aarch64-elf-gcc --version | head -n 1)"
    else
        cd $GCC64_DIR
        gcc64Type=$(git log --pretty=format:'%h: %s' -n1)
        cd $KERNEL_DIR
    fi
    if [ -e $GCC32_DIR/bin/arm-eabi-gcc ];then
        gcc32Type="$($GCC32_DIR/bin/arm-eabi-gcc --version | head -n 1)"
    else
        cd $GCC32_DIR
        gcc32Type=$(git log --pretty=format:'%h: %s' -n1)
        cd $KERNEL_DIR
    fi

	export KBUILD_BUILD_USER ARCH SUBARCH PATH \
		KBUILD_COMPILER_STRING BOT_MSG_URL \
		BOT_BUILD_URL PROCS TOKEN
}

##---------------------------------------------------------##

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##---------------------------------------------------------##

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

##----------------------------------------------------------##

tg_send_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
        -d sticker="$1" \
        -d chat_id="$CHATID"
}

##----------------------------------------------------------------##

tg_send_files(){
    KernelFiles="$(pwd)/$KERNELNAME.zip"
	MD5CHECK=$(md5sum "$KernelFiles" | cut -d' ' -f1)
	SID="CAACAgUAAxkBAAIlv2DEzB-BSFWNyXkkz1NNNOp_pm2nAAIaAgACXGo4VcNVF3RY1YS8HwQ"
	STICK="CAACAgUAAxkBAAIlwGDEzB_igWdjj3WLj1IPro2ONbYUAAIrAgACHcUZVo23oC09VtdaHwQ"
    MSG="✅ <b>Build Done</b>
- <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s) </code>

<b>Build Type</b>
-<code>$BUILD_TYPE</code>

<b>MD5 Checksum</b>
- <code>$MD5CHECK</code>

<b>Zip Name</b>
- <code>$KERNELNAME.zip</code>"

        curl --progress-bar -F document=@"$KernelFiles" "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHATID"  \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$MSG"

			tg_send_sticker "$SID"
}

##----------------------------------------------------------##

build_kernel() {
	if [ $INCREMENTAL = 0 ]
	then
		msg "|| Cleaning Sources ||"
		make clean && make mrproper && rm -rf out
	fi

	if [ "$PTTG" = 1 ]
 	then
            tg_post_msg "<b>🔨 EletroPerf Kernel Build Triggered</b>

<b>Docker OS: </b><code>$DISTRO</code>

<b>Build Host: </b><code>$KBUILD_BUILD_HOST</code>

<b>Host Core Count : </b><code>$PROCS</code>

<b>Device: </b><code>$MODEL</code>

<b>Codename: </b><code>$DEVICE</code>

<b>Build Date: </b><code>$DATE</code>

<b>Kernel Name: </b><code>ElectroPerf-LTO-$VARIANT-$DEVICE</code>

<b>Linux Tag Version: </b><code>$LINUXVER</code>

<b>ElectroPerf Build Progress: </b><a href='$SERVER_URL'> Check Here </a>

<b>Builder Info: </b>

<code>xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</code>

<code>- $gcc64Type </code>

<code>- $gcc32Type </code>

<code>xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</code>

#ElectroPerf #$VARIANT  #$DEVICE"

	tg_send_sticker "CAACAgQAAxkBAAIl2WDE8lfVkXDOvNEHqCStooREGW6rAAKZAAMWWwwz7gX6bxuxC-ofBA"

	fi

	if [ $SILENCE = "1" ]
	then
		MAKE+=( -s )
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
				STRIP=llvm-strip "${MAKE[@]}" 2>&1 | tee build.log

	elif [ $COMPILER = "gcc" ]
	then
		make -j"$PROCS" O=out \
				CROSS_COMPILE_ARM32=arm-eabi- \
				CROSS_COMPILE=aarch64-elf- \
				AR=aarch64-elf-ar \
				OBJDUMP=aarch64-elf-objdump \
				STRIP=aarch64-elf-strip  \
				LD="ld.lld"

	elif [ $COMPILER = "clangxgcc" ]
	then
		make -j"$PROCS"  O=out \
					CC=clang \
					CROSS_COMPILE=aarch64-linux-gnu- \
					CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
					AR=llvm-ar \
					AS=llvm-as \
					NM=llvm-nm \
					STRIP=llvm-strip \
					OBJCOPY=llvm-objcopy \
					OBJDUMP=llvm-objdump \
					OBJSIZE=llvm-size \
					READELF=llvm-readelf \
					HOSTCC=clang \
					HOSTCXX=clang++ \
					HOSTAR=llvm-ar \
					CLANG_TRIPLE=aarch64-linux-gnu- "${MAKE[@]}" 2>&1 | tee build.log
	fi

		BUILD_END=$(date +"%s")
		DIFF=$((BUILD_END - BUILD_START))

		if [ -f $KERNEL_DIR/out/arch/arm64/boot/$FILES ]
		then
			msg "|| Kernel successfully compiled ||"
			if [ $BUILD_DTBO = 1 ]
			then
				msg "|| Building DTBO ||"
				tg_post_msg "<code>Building DTBO..</code>"
				python2 "$KERNEL_DIR/scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
					create "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" --page_size=4096 "$KERNEL_DIR/out/arch/arm64/boot/dts/$DTBO_PATH"
			fi
				gen_zip
			else
			if [ "$PTTG" = 1 ]
 			then
				tg_post_msg "<b>❌Error! Compilaton failed: Kernel Image missing</b>

<b>Build Date: </b><code>$DATE</code>

<b>Kernel Name: </b><code>ElectroPerf-LTO-$VARIANT-$DEVICE</code>

<b>Linux Tag Version: </b><code>$LINUXVER</code>

<b>ElectroPerf Build Failure Logs: </b><a href='$SERVER_URL'> Check Here </a>

<b>Time Taken: </b><code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s)</code>

<b>Sed Loif Lmao</b>"

				tg_send_sticker "CAACAgUAAxkBAAIl1WDE8FQjVXrayorUvfFq4A7Uv9FwAAKaAgAChYYpVutaTPLAAra3HwQ"

				exit -1
			fi
		fi

}

##--------------------------------------------------------------##

gen_zip() {
	msg "|| Zipping into a flashable zip ||"
	mv "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb $AK_DIR/Image.gz-dtb
	if [ $BUILD_DTBO = 1 ]
	then
		mv "$KERNEL_DIR"/out/arch/arm64/boot/dtbo.img $AK_DIR/dtbo.img
	fi
	cd $AK_DIR
	cp -af "$KERNEL_DIR"/init.ElectroSpectrum.rc init.spectrum.rc && sed -i "s/persist.spectrum.kernel.*/persist.spectrum.kernel ElectroPerf-LTO-$VARIANT/g" init.spectrum.rc
        cp -af anykernel-real.sh anykernel.sh
	sed -i "s/kernel.string=.*/kernel.string=ElectroPerf-R-CAF-STABLE/g" anykernel.sh
	sed -i "s/kernel.for=.*/kernel.for=$VARIANT/g" anykernel.sh
	sed -i "s/kernel.compiler=.*/kernel.compiler=EVA-GCC/g" anykernel.sh
	sed -i "s/kernel.made=.*/kernel.made=Kunmun @ElectroPerf/g" anykernel.sh
	sed -i "s/kernel.version=.*/kernel.version=$LINUXVER/g" anykernel.sh
	sed -i "s/message.word=.*/message.word=Appreciate your efforts for choosing ElectroPerf kernel./g" anykernel.sh
	sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh

	cd $AK_DIR
	zip -r9 "$KERNELNAME.zip" * -x .git README.md anykernel-real.sh .gitignore zipsigner* *.zip

	if [ $SIGN = 1 ]
	then
		## Sign the zip before sending it to telegram
		if [ "$PTTG" = 1 ]
 		then
 			msg "|| Signing Zip ||"
			tg_post_msg "<code>Signing Zip file with AOSP keys..</code>"
 		fi
		cd $AK_DIR
		java -jar zipsigner-3.0.jar $KERNELNAME.zip $KERNELNAME-signed.zip
	fi

	if [ "$PTTG" = 1 ]
 	then
		tg_send_files "$1"
	fi
}

setversioning
clone
exports
build_kernel

##----------------*****-----------------------------##
