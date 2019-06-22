#!/bin/sh

echo "####################################################################################"
echo "# MiSTer installation script for Linux by rwk.                                     #"
echo "# based on Michael Smith (shmitty) <root@retrospace.be> macOS script               #"
echo "#                                                                                  #"
echo "# Thanks to rattboi who posted Naomi Peori's MiSTer SD Card Info file on the       #"
echo "# SmokeMonster Elite fpga-general discord channel and everyone involved and in and #"
echo "# using the MiSTer project.                                                        #"
echo "#                                                                                  #"
echo "# IMPORTANT: Use this script at your own risk. It WILL WIPE ALL DATA on the device #"
echo "# you specify. On standard Linux this is usually /dev/mmcblkX or /dev/sdX but make #"
echo "# sure to double check.                                                            #"
echo "#                                                                                  #"
echo "# Prerequisites:                                                                   #"
echo "# * git                                                                            #"
echo "# * wget                                                                           #"
echo "# * unrar                                                                          #"
echo "# (install using your packet manager: e.g., apt-get install git wget unrar).       #"
echo "# (if something else is missing install it ...)                                    #"
echo "####################################################################################"
echo ""

# Script configuration
DOWNLOAD_DIRECTORY=./download

# TODO(m): Remove hardcoded versions.
# URLs
RELEASE_URL='https://github.com/MiSTer-devel/SD-Installer-Win64_MiSTer/raw/master/release_20190510.rar'
RECENT_MISTER_URL='https://github.com/MiSTer-devel/Main_MiSTer/raw/master/releases/MiSTer_20190513'
RECENT_MENU_MISTER_URL='https://github.com/MiSTer-devel/Menu_MiSTer/raw/master/releases/menu_20190226.rbf'
UPDATER_SCRIPT_URL='https://raw.githubusercontent.com/MiSTer-devel/Updater_script_MiSTer/master/update.sh'

# Sanity checks
if [ -z "$1" ]; then
    echo ""
    echo "Usage: $0 [DEVICE]"
    echo ""
    echo "Please read README.md and specify an SD card device."
    echo ""
    exit 1
fi

# Check prerequisites
command -v git >/dev/null 2>&1 || { echo >&2 "I require 'git' but it's not installed. Aborting."; exit 1; }
command -v wget >/dev/null 2>&1 || { echo >&2 "I require 'wget' but it's not installed. Aborting."; exit 1; }
command -v unrar >/dev/null 2>&1 || { echo >&2 "I require 'unrar' but it's not installed. Aborting."; exit 1; }

# Set SD card device
DEVICE=$1

# Check if the device exists
if [ ! -e $DEVICE ]; then
    echo ""
    echo "Error: Device $DEVICE not found."
    echo ""
    exit 1
fi

echo "This will erase $DEVICE are you sure you want to continue ? [y/n]"
read ans
if [ "$ans" != "${ans#[Yy]}" ] ;then
    echo "Okay ! Here we go !"
else
    exit 1
fi

mkdir -p $DOWNLOAD_DIRECTORY

echo "Fetching installation files..."
wget -nv --progress=bar --show-progress -O $DOWNLOAD_DIRECTORY/release.rar $RELEASE_URL
echo ""

echo "Extracting installation files..."
unrar x -y $DOWNLOAD_DIRECTORY/release.rar $DOWNLOAD_DIRECTORY
echo ""

echo "Unmounting potentially mounted partitions (sudo may ask for your password)"
sudo umount ${DEVICE}*
echo ""

# Note : Uboot and FSBL code is loaded from partition with a2 ID (can be any of the 4 partitions in the MBR) see :
# https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/hb/cyclone-v/cv_5v4.pdf
# Page 3481 (Section A-13) "Flash Memory Devices for Booting"
# However Uboot (the Uboot that comes with MiSTer) will try to boot linux from partition 1
# Here we create a partition 1 that takes all the remaining space of the SD card from sector 4096+
# and partition 2 which spans from sector 2048 to 4095 (for Uboot and the FSBL code)
echo "Creating SD Card partition table"
sudo sfdisk --force ${DEVICE} << EOF
4096;
2048,2048
EOF
echo ""
# Having the partitions in reverse order relative to their position on the disk is a bit dodgy, this
# was done so that the first partition could be extended to the end of the disk while the second
# partition would only span 1M ... If someone has a better solution go ahead

# We set the special partition magic ID (a2) as said in the manual using sfdisk and sed
echo "Setting partition table, sfdisk may complain, don't worry"
sudo sfdisk -d ${DEVICE} | sed '0,/type=.*$/s//type=7/' | sed '0,/type=.*$/! s/type=.*$/type=a2/' | sudo sfdisk --force ${DEVICE}
echo ""

echo "Writing uboot image to the UBOOT partition" # Partition 2 (but at the start of the disk)
UBOOT_PART=$(ls ${DEVICE}*2)
sudo dd if=${DOWNLOAD_DIRECTORY}/files/linux/uboot.img of=${UBOOT_PART} bs=64k
echo ""

echo "Creating the MiSTer_Data partition" # Partition 1 (since Uboot will load Linux from Part 1, see env)
sudo mkfs.exfat -n "MiSTer_Data" ${DEVICE}*1
echo ""

echo "Syncing"
sudo sync
echo ""

echo "Mounting the disk"
mkdir -p ./mnt/MiSTer_Data/
sudo mount -t exfat ${DEVICE}*1 ./mnt/MiSTer_Data/
echo ""

echo "Copying MiSTer files..."
cp -Rv $DOWNLOAD_DIRECTORY/files/* ./mnt/MiSTer_Data/
echo ""

echo "Downloading and installing a recent MiSTer binary..."
wget -nv --progress=bar --show-progress -O ./mnt/MiSTer_Data/MiSTer $RECENT_MISTER_URL
echo ""

echo "Downloading and installing a recent MiSTer menu core..."
wget -nv --progress=bar --show-progress -O ./mnt/MiSTer_Data/menu.rbf $RECENT_MENU_MISTER_URL
echo ""

echo "Downloading and installing the MiSTer updater script..."
mkdir -p './mnt/MiSTer_Data/#Scripts'
wget -N -nv --progress=bar --show-progress --directory-prefix './mnt/MiSTer_Data/#Scripts' \
$UPDATER_SCRIPT_URL
echo ""

echo "Syncing data to SD card before ejection"
sudo sync
echo ""

echo "Unmounting SD card..."
sudo umount ./mnt/MiSTer_Data/
rmdir ./mnt/MiSTer_Data
rmdir ./mnt
echo ""
echo ""

echo "All done. Put the SD card into your MiSTer and start it up."
echo "Connect a keyboard to the MiSTer and hit F12 to bring up the menu."
echo "Refer to the MiSTer wiki for further information."
echo ""
