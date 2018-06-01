#!/bin/bash
# Nombre: main.sh
# Description: Main Script
#############################

# Global Parameters
set -e # No errors allowed

#############################

## Usage: FexChange <fexfile> <section> <key> <value> 
## Description: Changes the value of a given key (or adds key=value) to a specific section of FEX file
FexChange()
{
	# Search in file ($1) in section ($2) for key ($3)
	found=$(sed -n -e "/^\[$2\]/,/^\[/{/^$3\s*=/p}" "$1")
  
	if [ -n "$found" ]; then
		# Replace in file ($1) in section ($2) key ($3) with value ($4)
		sed -i -e "/^\[$2\]/,/^\[/{s/^\($3\s*=\s*\).*/\1$4/}" "$1"
	else
		# Append in file ($1) in section ($2) key ($3) with value ($4)
		sed -i -e "/^\[$2\]/,/^\[/{/^\[/i$3 = $4\n" -e "}" "$1"
	fi
}

## Usage: RetrocfgChange <file_path> <key> <value> 
## Description: Changes the value of a given key (or adds key=value) of retroarch.cfg file
RetrocfgChange()
{
	# Search in file ($1) for key ($2)
	found=$(sed -n -e "/^$2\s*=/p" "$1")
  
	if [ -n "$found" ]; then
		# Replace in file ($1) key ($2) with value ($3)
		sed -i -e "s/^\($2\s*=\s*\).*/\1$3/" "$1"
	else
		# Append in file ($1) key ($2) with value ($3)
		sed -i -e "\$a$2 = $3" "$1"
	fi
}

#############################

# Menu Screen. Select option
OPTION=$(whiptail --title "BashTool_ROPI_RCA" --menu "Choose an option" 15 60 0 --cancel-button Exit --ok-button Select \
	"1" "HDMI Video 720p & Audio (default)." \
	"2" "HDMI Video 720p & Analog Audio" \
	"3" "Analog Video (PAL) & Audio. Overscan fixed." \
	"4" "Analog Video (NTSC) & Audio. Overscan fixed." \
	"5" "Default Analog Video (PAL) & Audio." \
	"6" "Default Analog Video (NTSC) & Audio." \
	"7" "Switch to USB Audio." \
	"8" "Switch to Analog Audio." \
	3>&1 1>&2 2>&3)

# Manage Option Selected. Configure System Video & Audio Output
if [ $OPTION = "1" ]; then # Set: HDMI Video & Audio
	echo "Configuring, please wait..."
	sleep 2
	
	######## Video setup
	
	# Script.bin modification
	bin2fex /boot/script.bin /boot/script.fex
	FexChange "/boot/script.fex" "disp_init" "disp_mode" "0" # Use Screen0 configs
	FexChange "/boot/script.fex" "disp_init" "screen0_output_type" "3" # HDMI
	FexChange "/boot/script.fex" "disp_init" "screen0_output_mode" "5" # 720p
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_height" "0" # default setting
	FexChange "/boot/script.fex" "hdmi_para" "hdmi_used" "1" # Turn on HDMI
	FexChange "/boot/script.fex" "tv_para" "tv_used" "0" # Turn off RCA
	FexChange "/boot/script.fex" "audiohub" "hub_used" "0" # Disable Audio HUB
	FexChange "/boot/script.fex" "audiohub" "spdif_used" "0" # Disable SPDIF
	fex2bin /boot/script.fex /boot/script.bin
	
	# TV module load
	sed -i '/tv/d' /etc/modules # Delete "tv" line
	sed -i '/^ *$/d' /etc/modules # Delete empty lines
	
	######## Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '""'
	cp -a files/hdmi/asound.conf /etc/asound.conf
	cp -a files/hdmi/asoundrc /home/pi/.asoundrc
	
elif [ $OPTION = "2" ]; then # Set: HDMI Video. Analog Audio
	echo "Configuring, please wait..."
	sleep 2
	
	######## Video setup

	# Script.bin modification
	bin2fex /boot/script.bin /boot/script.fex
	FexChange "/boot/script.fex" "disp_init" "disp_mode" "0" # Use Screen0 configs
	FexChange "/boot/script.fex" "disp_init" "screen0_output_type" "3" # HDMI
	FexChange "/boot/script.fex" "disp_init" "screen0_output_mode" "5" # 720p
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_height" "0" # default setting
	FexChange "/boot/script.fex" "hdmi_para" "hdmi_used" "1" # Turn on HDMI
	FexChange "/boot/script.fex" "tv_para" "tv_used" "0" # Turn off RCA
	FexChange "/boot/script.fex" "audiohub" "hub_used" "1" # Enable Audio HUB
	FexChange "/boot/script.fex" "audiohub" "spdif_used" "0" # Disable SPDIF
	fex2bin /boot/script.fex /boot/script.bin

	# TV module unload
	sed -i '/tv/d' /etc/modules # Delete "tv" line
	sed -i '/^ *$/d' /etc/modules # Delete empty lines
	
	######## Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:0,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/rca/asound.conf /etc/asound.conf
	cp -a files/rca/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

elif [ $OPTION = "3" ]; then # Set: Analog Video (PAL) & Audio
	echo "Configuring, please wait..."
	sleep 2
	
	# Video setup
	
	# Script.bin modification
	bin2fex /boot/script.bin /boot/script.fex
	FexChange "/boot/script.fex" "disp_init" "disp_mode" "1" # Use Screen1 configs
	FexChange "/boot/script.fex" "disp_init" "screen1_output_type" "2" # TV
	FexChange "/boot/script.fex" "disp_init" "screen1_output_mode" "11" # PAL
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "664" # underscan setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "544" # underscan setting
        FexChange "/boot/script.fex" "disp_init" "fb1_width" "664" # underscan setting
        FexChange "/boot/script.fex" "disp_init" "fb1_height" "544" # underscan setting
     	FexChange "/boot/script.fex" "hdmi_para" "hdmi_used" "0" # Turn off HDMI
	FexChange "/boot/script.fex" "tv_para" "tv_used" "1" # Turn on RCA
	FexChange "/boot/script.fex" "audiohub" "hub_used" "1" # Enable Audio HUB
	FexChange "/boot/script.fex" "audiohub" "spdif_used" "0" # Disable SPDIF
	fex2bin /boot/script.fex /boot/script.bin

	# TV module unload
	sed -i '/tv/d' /etc/modules # Delete "tv" line
	sed -i '/^ *$/d' /etc/modules # Delete empty lines
	echo "tv" >> /etc/modules

        # Adding tvout_manipulator to /etc/rc.local
        sed -i '/^ *$/d' /etc/rc.local # Delete empty lines
        sed -i '/tvout/d' /etc/rc.local # Delete previous tvout entries
        sed -i -e '$i \sudo /home/pi/RetrOrangePi/overscan_fix/src/bin/Release/tvout -m -x 40 -y 10\n' /etc/rc.local
	
	# Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:0,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/rca/asound.conf /etc/asound.conf
	cp -a files/rca/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

elif [ $OPTION = "4" ]; then # Set: Analog Video (NTSC) & Audio
	echo "Configuring, please wait..."
	sleep 2
	
	# Video setup
	
	# Script.bin modification
	bin2fex /boot/script.bin /boot/script.fex
	FexChange "/boot/script.fex" "disp_init" "disp_mode" "1" # Use Screen1 configs
	FexChange "/boot/script.fex" "disp_init" "screen1_output_type" "2" # TV
	FexChange "/boot/script.fex" "disp_init" "screen1_output_mode" "14" # NTSC
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "672" # underscan setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "448" # underscan setting
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "672" # underscan setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "448" # underscan setting
	FexChange "/boot/script.fex" "hdmi_para" "hdmi_used" "0" # Turn off HDMI
	FexChange "/boot/script.fex" "tv_para" "tv_used" "1" # Turn on RCA
	FexChange "/boot/script.fex" "audiohub" "hub_used" "1" # Enable Audio HUB
	FexChange "/boot/script.fex" "audiohub" "spdif_used" "0" # Disable SPDIF
	fex2bin /boot/script.fex /boot/script.bin

	# TV module unload
	sed -i '/tv/d' /etc/modules # Delete "tv" line
	sed -i '/^ *$/d' /etc/modules # Delete empty lines
	echo "tv" >> /etc/modules

        # Adding tvout_manipulator to /etc/rc.local
	sed -i '/^ *$/d' /etc/rc.local # Delete empty lines
	sed -i '/tvout/d' /etc/rc.local # Delete previous tvout entries
	sed -i -e '$i \sudo /home/pi/RetrOrangePi/overscan_fix/src/bin/Release/tvout -m -x 50 -y 20\n' /etc/rc.local

	# Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:0,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/rca/asound.conf /etc/asound.conf
	cp -a files/rca/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

elif [ $OPTION = "5" ]; then # Set: Default Analog Video (PAL) & Audio
	echo "Configuring, please wait..."
	sleep 2
	
	# Video setup
	
	# Script.bin modification
	bin2fex /boot/script.bin /boot/script.fex
	FexChange "/boot/script.fex" "disp_init" "disp_mode" "1" # Use Screen1 configs
	FexChange "/boot/script.fex" "disp_init" "screen1_output_type" "2" # TV
	FexChange "/boot/script.fex" "disp_init" "screen1_output_mode" "11" # PAL
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_height" "0" # default setting
     	FexChange "/boot/script.fex" "hdmi_para" "hdmi_used" "0" # Turn off HDMI
	FexChange "/boot/script.fex" "tv_para" "tv_used" "1" # Turn on RCA
	FexChange "/boot/script.fex" "audiohub" "hub_used" "1" # Enable Audio HUB
	FexChange "/boot/script.fex" "audiohub" "spdif_used" "0" # Disable SPDIF
	fex2bin /boot/script.fex /boot/script.bin

	# TV module unload
	sed -i '/tv/d' /etc/modules # Delete "tv" line
	sed -i '/^ *$/d' /etc/modules # Delete empty lines
	echo "tv" >> /etc/modules
	
	# cleaning overscan leftovers
        sed -i '/tvout/d' /etc/rc.local # Delete previous tvout entries

	# Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:0,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/rca/asound.conf /etc/asound.conf
	cp -a files/rca/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

elif [ $OPTION = "6" ]; then # Set: Default Analog Video (NTSC) & Audio
	echo "Configuring, please wait..."
	sleep 2
	
	# Video setup
	
	# Script.bin modification
	bin2fex /boot/script.bin /boot/script.fex
	FexChange "/boot/script.fex" "disp_init" "disp_mode" "1" # Use Screen1 configs
	FexChange "/boot/script.fex" "disp_init" "screen1_output_type" "2" # TV
	FexChange "/boot/script.fex" "disp_init" "screen1_output_mode" "14" # NTSC
        FexChange "/boot/script.fex" "disp_init" "fb0_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb0_height" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_width" "0" # default setting
        FexChange "/boot/script.fex" "disp_init" "fb1_height" "0" # default setting
     	FexChange "/boot/script.fex" "hdmi_para" "hdmi_used" "0" # Turn off HDMI
	FexChange "/boot/script.fex" "tv_para" "tv_used" "1" # Turn on RCA
	FexChange "/boot/script.fex" "audiohub" "hub_used" "1" # Enable Audio HUB
	FexChange "/boot/script.fex" "audiohub" "spdif_used" "0" # Disable SPDIF
	fex2bin /boot/script.fex /boot/script.bin

	# TV module unload
	sed -i '/tv/d' /etc/modules # Delete "tv" line
	sed -i '/^ *$/d' /etc/modules # Delete empty lines
	echo "tv" >> /etc/modules

	# cleaning overscan leftovers
        sed -i '/tvout/d' /etc/rc.local # Delete previous tvout entries

	# Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:0,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/rca/asound.conf /etc/asound.conf
	cp -a files/rca/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

elif [ $OPTION = "7" ]; then # Set: Switch to USB Audio
	echo "Configuring, please wait..."
	sleep 2

	# Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:2,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/usb/asound.conf /etc/asound.conf
	cp -a files/usb/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

elif [ $OPTION = "8" ]; then # Set: Switch to Analog Audio
	echo "Configuring, please wait..."
	sleep 2

	# Audio setup
	RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_device' '"hw:0,0"'
        RetrocfgChange '/opt/retropie/configs/all/retroarch.cfg' 'audio_driver' '"sdl2"'
	cp -a files/rca/asound.conf /etc/asound.conf
	cp -a files/rca/asoundrc /home/pi/.asoundrc
	amixer -c 0 set "Audio lineout" unmute

else
	echo "Tool Error"
	exit
fi

# Need Reboot Screen. Do It?
whiptail --title "BashTool_ROPI_RCA" --msgbox "Configuration applied" 10 55 5
if (whiptail --title "BashTool_ROPI_RCA" --yesno "It is necessary to reboot the system. Reboot now?" 8 78) then
	# Yes
	reboot
else
	# No
	exit
fi
