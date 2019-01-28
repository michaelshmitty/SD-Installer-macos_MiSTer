# MiSTer SD card installer (macOS)

This script automates the creation of a MiSTer SD card on macOS.
Tested on macOS Mojave 10.14.2

Running this script on an empty SD card will install the following:
* Linux OS img for the HPS.
* A recent MiSTer binary.
* A recent MiSTer menu core.
* [Locutus73's awesome MiSTer update script](https://github.com/MiSTer-devel/Updater_script_MiSTer)

Once your SD card is ready you can put it into your MiSTer board, configure a controller and run
[the MiSTer update script](https://github.com/MiSTer-devel/Updater_script_MiSTer).
This will install the latest versions of the MiSTer binary, the menu and the MiSTer cores.
Make sure your MiSTer board is connected to the Internet using ethernet.

## Prerequisites
* git (install using [homebrew](https://brew.sh/): brew install git)
* wget (install using [homebrew](https://brew.sh/): brew install wget).
* unrar (install using [homebrew](https://brew.sh/): brew install unrar).

## Usage
Open a terminal, clone this repository and change into the directory.

```bash
git clone https://github.com/michaelshmitty/SD-Installer-macos_MiSTer.git
cd SD-Installer-macos_MiSTer
```

Find out your SD card device. This is important because the script will wipe everything
on that device and selecting the wrong device could lead to data loss.

First, keep your SD card unplugged and list the currrently known disks:
```bash
diskutil list
```

Then insert your SD card and issue the command again. Your SD card should now show up in the list.
Usually it's /dev/disk2 but not always.
```bash
diskutil list
```

Now run the macOS MiSTer SD card installer script with the correct disk, for example /dev/disk2.
Some commands require the sudo command so you may be prompted for your password.
```bash
./MiSTer-sd-installer-macos.sh /dev/disk2
```

If everything went well you should now have a clean MiSTer SD card which you can put into your
MiSTer board and boot from.

Once booted you will be greeted by the MiSTer interface. Attach a keyboard and make sure your
MiSTer board is connected to the internet through the ethernet interface.
Hit F12 on the keyboard and navigate to Scripts. Then open the #Scripts directory, select the
update script and hit enter.
[The MiSTer update script](https://github.com/MiSTer-devel/Updater_script_MiSTer) will now install
the latest versions of the MiSTer binary, the menu and the available MiSTer cores.
