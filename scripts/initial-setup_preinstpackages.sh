#!/bin/bash

# This script prepares an Armbian Bionic image 
# for the Cardano on the Rocks (RockPi) project
#
# Author: m@rkus.it
# version 2019-09-09

main() {

	# collect system values
	BOARD=`uname -n`
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		OS=$NAME
		VER=$VERSION_ID
	fi
	
	# set parameters for supported SBC's
	if [[ "$BOARD" == "rockpi" && "$OS" == "Ubuntu" ]]; then
		SUPPORTEDSYSTEM=true
		#GPIO numbers for the RGB-Led pins
		RGB_GPIO_RED=157
		RGB_GPIO_GREEN=156
		RGB_GPIO_BLUE=154
		#OLED settings
		OLED_I2C_PORT=2
		OLED_ORIENTATION=2
		OLED_DISPLAY_TYPE='sh1106'
	fi
	
	if [[ "$SUPPORTEDSYSTEM" = true ]]; then
		
		say "OK, let's prepare this $OS installation on the $BOARD" "log"
		
		# turn on the blue led
		cd /sys/class/gpio
		echo $RGB_GPIO_BLUE > export
		cd gpio$RGB_GPIO_BLUE
		echo out > direction
		echo 1 > value
		
		# pimp apt to retry 3 times (for weak internet connections)
		echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries
		
		say "turn also green LED on" "log"
		cd /sys/class/gpio
		echo $RGB_GPIO_GREEN > export
		cd gpio$RGB_GPIO_GREEN
		echo out > direction
		echo 1 > value
		cd ~
		
		say "clone OLED library" "log"
		mkdir ~/cardano-on-the-rocks
		cd ~/cardano-on-the-rocks
		git clone https://github.com/clio-one/luma.oled.git
		
		say "install OLED library" "log"
		cd luma.oled
		sudo python setup.py install
		cd ..
		
		say "clone Cardano display content" "log"
		git clone https://github.com/clio-one/cardano-luma.git
		
		say "blue and green LED off" "log"
		cd /sys/class/gpio
		echo $RGB_GPIO_GREEN > export
		cd gpio$RGB_GPIO_GREEN
		echo out > direction
		echo 0 > value
		cd ..
		echo $RGB_GPIO_BLUE > export
		cd gpio$RGB_GPIO_BLUE
		echo out > direction
		echo 0 > value
		cd ~
		
		say "Show Cardano Logo on Display" "log"
		sudo python ~/cardano-on-the-rocks/cardano-luma/examples/cardano-animation.py --display $OLED_DISPLAY_TYPE --i2c-port $OLED_I2C_PORT --rotate $OLED_ORIENTATION
		
		say "green LED on" "log"
		cd /sys/class/gpio
		echo $RGB_GPIO_GREEN > export
		cd gpio$RGB_GPIO_GREEN
		echo out > direction
		echo 1 > value
		cd ~
		
		say "install and enable the firewall" "log"
		aptInstall iptables
		aptInstall ufw
		ufw allow ssh/tcp
		ufw logging on
		ufw --force enable
		
		say "Completing the initial setup and prepare for future boots" "log"
		say "remove the initial setup script" "log"
		chmod -x /usr/local/bin/cardano-on-the-rocks.sh
		mv /usr/local/bin/cardano-on-the-rocks.sh /usr/local/bin/cardano-on-the-rocks_initial-setup-DONE.sh
		say "create a new service helper script" "log"
		cat > /usr/local/bin/cardano-on-the-rocks.sh <<- EOF
		#!/bin/bash
		
		RGB_GPIO_RED=$RGB_GPIO_RED
		RGB_GPIO_GREEN=$RGB_GPIO_GREEN
		RGB_GPIO_BLUE=$RGB_GPIO_BLUE
		
		say() {
		  echo $1
		  if [[ \$2 == "log" ]]; then 
		    echo "\$(date -Iseconds) - \$1" >> /var/log/cardano-on-the-rocks.log
		  fi
		}
		
		aptInstall() {
		  say "install \$1" "log"
		  sudo DEBIAN_FRONTEND=noninteractive apt-get --yes install \$1
		}
		
		say "Cardano-on-the-Rocks service started"
		
		sudo python ~/cardano-on-the-rocks/cardano-luma/examples/cardano-animation.py --display $OLED_DISPLAY_TYPE --i2c-port $OLED_I2C_PORT --rotate $OLED_ORIENTATION
		
		# turn green RGBLed on
		cd /sys/class/gpio
		echo \$RGB_GPIO_GREEN > export
		cd gpio\$RGB_GPIO_GREEN
		echo out > direction
		echo 1 > value
		
		sudo python ~/cardano-on-the-rocks/cardano-luma/examples/cardano.py --display $OLED_DISPLAY_TYPE --i2c-port $OLED_I2C_PORT --rotate $OLED_ORIENTATION
		
		say "launch apt-get update"
		apt-get --yes update
EOF
		
		chmod +x /usr/local/bin/cardano-on-the-rocks.sh
		
		say "reboot the device after initial setup" "log"
		reboot
		
	else
		say "Sorry: This script is not made for $OS on $BOARD"
	fi
}



####################################
# helper functions for main
####################################

say() {
	echo $1
	if [[ $2 == "log" ]]; then 
		echo "$(date -Iseconds) - $1" >> /var/log/cardano-on-the-rocks.log
	fi
}

err() {
	say "$1" >&2
	exit 1
}

need_cmd() {
	if ! check_cmd "$1"; then
		err "need '$1' (command not found)"
	fi
}

verify_cmd() {
	if ! check_cmd "$1"; then
		say "cmd '$1' not found" "log"
		# turn blue/green off and red RGBLed on
		cd /sys/class/gpio
		echo \$RGB_GPIO_BLUE > export
		cd gpio\$RGB_GPIO_BLUE
		echo out > direction
		echo 0 > value		
		cd /sys/class/gpio
		echo \$RGB_GPIO_GREEN > export
		cd gpio\$RGB_GPIO_GREEN
		echo out > direction
		echo 0 > value		
		echo \$RGB_GPIO_RED > export
		cd gpio\$RGB_GPIO_RED
		echo out > direction
		echo 1 > value		
		exit 1
	fi
}

check_cmd() {
	command -v "$1" > /dev/null 2>&1
}

aptInstall() {
	# apt-get install a package
	# optional blink the blue led
	if [[ -n $2 ]]; then
		cd /sys/class/gpio
		echo $RGB_GPIO_BLUE > export
		cd gpio$RGB_GPIO_BLUE
		echo out > direction
		echo 0 > value
		sleep $2
		echo 1 > value
	fi
	say "install $1" "log"
	sudo DEBIAN_FRONTEND=noninteractive apt-get --yes install $1
	# verfiy if successfully downloaded and installed. if not show red and exit the script 
	# verify_cmd $1
}



# execute main functions

main "$@" || exit 1
