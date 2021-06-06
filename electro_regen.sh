#! /bin/bash

 # Script For Regenerating Defconfig of Android arm64 Kernel
 #
 # Copyright (c) 2021 ElectroPerf <kunmun.devroms@gmail.com>
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
DEFCONFIG=electroperf_defconfig

# Show manufacturer info
MANUFACTURERINFO="ASUSTek Computer Inc."

# Define Kernel Arch
KARCH=arm64

# Commit Your Changes
AUTO_COMMIT=1

	msg "|| Export Kernel Arch ||"

	export ARCH=$KARCH

	msg "|| Cleaning Sources ||"

	make clean && make mrproper

	msg "|| Regenerating Defconfig ||"

	make $DEFCONFIG

	msg "|| Removing Old Defconfig ||"

	rm -rf arch/$KARCH/configs/$DEFCONFIG

	msg "|| Moving Regenerated Defconfig ||"

	mv .config arch/$KARCH/configs/$DEFCONFIG

	if [ $AUTO_COMMIT = 1 ]
	then
		msg "|| Commiting Changes ||"

		git add arch/$KARCH/configs/$DEFCONFIG
		git commit -m "$DEFCONFIG: Regenerate" --signoff

	fi
