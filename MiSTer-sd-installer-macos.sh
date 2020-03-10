#!/bin/sh

echo "####################################################################################"
echo "# MiSTer installation script for macOS.                                            #"
echo "# by Michael Smith (shmitty) <root@retrospace.be>                                  #"
echo "#                                                                                  #"
echo "# Thanks to rattboi who posted Naomi Peori's MiSTer SD Card Info file on the       #"
echo "# SmokeMonster Elite fpga-general discord channel and everyone involved and in and #"
echo "# using the MiSTer project.                                                        #"
echo "#                                                                                  #"
echo "# IMPORTANT: Use this script at your own risk. It WILL WIPE ALL DATA on the device #"
echo "# you specify. On standard macOS this is usually /dev/disk2 but make sure to       #"
echo "# double check.                                                                    #"
echo "#                                                                                  #"
echo "# Prerequisites:                                                                   #"
echo "# * git (install using homebrew: brew install git).                                #"
echo "# * wget (install using homebrew: brew install wget).                              #"
echo "# * unrar (install using homebrew: brew install unrar).                            #"
echo "#                                                                                  #"
echo "####################################################################################"
echo ""

# Script configuration
DOWNLOAD_DIRECTORY=./download

# TODO(m): Remove hardcoded versions.
# URLs
RELEASE_URL='https://github.com/MiSTer-devel/SD-Installer-Win64_MiSTer/raw/master/release_20200122.rar'
RECENT_MISTER_URL='https://github.com/MiSTer-devel/Main_MiSTer/raw/master/releases/MiSTer_20200308'
RECENT_MENU_MISTER_URL='https://github.com/MiSTer-devel/Menu_MiSTer/raw/master/releases/menu_20200115.rbf'
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

mkdir -p $DOWNLOAD_DIRECTORY

echo "Fetching installation files..."
wget -nv --progress=bar --show-progress -O $DOWNLOAD_DIRECTORY/release.rar $RELEASE_URL
echo ""

echo "Extracting installation files..."
unrar x -y $DOWNLOAD_DIRECTORY/release.rar $DOWNLOAD_DIRECTORY
echo ""

echo "Partitioning SD card..."
diskutil partitionDisk ${DEVICE} MBR ExFAT MiSTer_Data R ExFAT UBOOT 3M
echo ""

echo "Copying MiSTer files..."
if [ -d /Volumes/MiSTer_Data ]; then
    cp -Rv $DOWNLOAD_DIRECTORY/files/* /Volumes/MiSTer_Data/
else
    echo "Error: /Volumes/MiSTer_Data is not mounted."
    echo "Something probably went wrong during the parititioning step."
    echo "Eject the SD card and try again."
    exit 1
fi
echo ""

echo "Downloading and installing a recent MiSTer binary..."
wget -nv --progress=bar --show-progress -O /Volumes/MiSTer_Data/MiSTer $RECENT_MISTER_URL
echo ""

echo "Downloading and installing a recent MiSTer menu core..."
wget -nv --progress=bar --show-progress -O /Volumes/MiSTer_Data/menu.rbf $RECENT_MENU_MISTER_URL
echo ""

echo "Downloading and installing the MiSTer updater script..."
mkdir -p '/Volumes/MiSTer_Data/#Scripts'
wget -N -nv --progress=bar --show-progress --directory-prefix '/Volumes/MiSTer_Data/#Scripts' \
$UPDATER_SCRIPT_URL
echo ""

echo "Unmounting SD card..."
diskutil unmountDisk ${DEVICE}
echo ""
echo ""

echo "Fixing the SD card partition table to support UBOOT (sudo may ask for your password)..."
echo "You may see a message 'could not open MBR file' which is safe to ignore."
sudo fdisk -d ${DEVICE} | sed 'n;s/0x07/0xA2/g' | sudo fdisk -ry ${DEVICE}
echo ""

echo "Writing uboot image to the UBOOT partition (sudo may ask for your password)..."
sudo dd if=${DOWNLOAD_DIRECTORY}/files/linux/uboot.img of=${DEVICE}s2 bs=64k
echo ""

echo "Disabling Spotlight indexing and removing relevant Spotlight folders..."
mdutil -d /Volumes/MiSTer_Data
rm -rf /Volumes/MiSTer_Data/.Spotlight-V100
rm -rf /Volumes/MiSTer_Data/.fseventsd
echo ""

echo "Ejecting SD card (this can take a few seconds)..."
diskutil eject ${DEVICE}
echo ""

echo "All done. Put the SD card into your MiSTer and start it up."
echo "Connect a keyboard to the MiSTer and hit F12 to bring up the menu."
echo "Refer to the MiSTer wiki for further information."
echo ""
