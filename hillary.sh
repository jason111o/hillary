#!/usr/bin/env bash
#### Written by Jason Pippin
version="hillary-1.4"

######################################Main######################################
main() {
	echo $version
	check_su
	check_for_dependencies
	dependencies_needed
	while true; do
		free_cache
		user_set
		run_bleachbit
		partition_display
		zero_file
		find_zero_files
	done
}
################################################################################

#### Set some prompt colors
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
NOCOLOR='\033[0m'

#### Check for super powers
check_su() {
	if [[ $EUID != 0 ]]; then
		echo -e "${WHITE}You do not have permission!${NOCOLOR}"; sleep 1
		exit 1
	fi
}

#### Check for dependencies
check_for_dependencies() {
	depends=("sudo" "sleep" "bleachbit" "dd" "free" "sync")
	depends_not_installed=()
	echo -e "Checking dependencies..."
	for x in ${depends[@]}; do
		xpath=$(command -v $x)
		if [[ "$xpath" ]]; then
			sleep 0.25
			#echo -e "${WHITE}[${GREEN}+${WHITE}] $x"
		elif [[ ! "$xpath" ]]; then
			sleep 0.25
			#echo -e "${WHITE}[${RED}-${WHITE}] $x"
			depends_not_installed+=("$x")
		fi
	done
	sleep 1
}
#### If dependencies are needed then prompt the user to install them
dependencies_needed() {
	len=${#depends_not_installed}
	while [ $len -gt 0 ]; do
		echo -e "${WHITE}Install missing dependencies? y/n/e${NOCOLOR}"
		read ans
		if [[ "$ans" == "y" ]]; then
			for x in ${depends_not_installed[@]}; do
				apt install  "$x"
				if [[ $? != 0 ]]; then
					echo -e "${YELLOW}"$x" was not found in your distribution package sources."
					echo -e "Check your distros documentation.${NOCOLOR}\n"
				fi
				check_for_dependencies
				len=${#depends_not_installed}
				if [[ $len == 0 ]]; then
					echo -e "${WHITE}Dependencies have been satisfied. Press enter to continue...${NC}"
				fi
			done
		elif [[ "$ans" == "n" ]]; then
			echo -e "${CYAN}This script needs..."
			for x in ${depends_not_installed[@]}; do
				echo -e "${WHITE}----> ${RED}$x"
				sleep 0.5
			done
			echo -e "${CYAN}in order to work.${NOCOLOR}\n"
		elif [[ $ans == "e" ]]; then
			echo -e "${WHITE}Exiting...${NOCOLOR}\n"
			sleep 1
			exit 1
		elif [[ "$len" == 0 ]]; then
			break
		fi
	done
}

#### Display memory use and clear cache if the user chooses so
free_cache() {
	clear
	echo -e "${YELLOW}Current memory stat:${NOCOLOR}"
	free -h
	echo -e "${CYAN}Would you like to free memory/caches?${WHITE}\nY/n/e${NOCOLOR}"
	read ans
	if [[ $ans != "n" ]] && [[ $ans != "e" ]]; then
		drop_caches_path=$(find /proc -name drop_caches 2>/dev/null)
		echo -e "${YELLOW}Applications/Programs may start slower after cleaning as the system resumes new cache creations."
		echo -e "${WHITE}1. Free page cache"
		echo -e "2. Free reclaimable slab objects (includes dentries and inodes)"
		echo -e "3. Free page cache and slab objects\n1/2/3/n${NOCOLOR}"
		read num
		while true; do
			if [[ $num != 1 ]] && [[ $num != 2 ]] && [[ $num != 3 ]] && [[ $num != "n" ]]; then
				echo -e "${YELLOW}You must enter a 1, 2, or 3 for cache or \"n\" to continue.${NOCOLOR}"
				echo -e "${WHITE}1/2/3/n${NOCOLOR}"
				read num
			elif [[ $num == 1 ]] || [[ $num == 2 ]] || [[ $num == 3 ]]; then
				# sync the system before clearing cache
				sync
				echo $num > $drop_caches_path
				sleep 1
				echo -e "${YELLOW}New memory stat:${NOCOLOR}"
				free -h
				echo -e "\n${CYAN}Press ENTER to continue.${NOCOLOR}"
				read anything
				break
			elif [[ $num == "n" ]]; then
				break
			else
				exit 1
			fi
		done
	elif [[ $ans == "n" ]]; then
		break
	elif [[ $ans == "e" ]]; then
		echo -e "${WHITE}Exiting...${NOCOLOR}"
		sleep 1
		exit 0
	fi
}

#### Set all users whom have a home directory to an array
user_set() {
	all_users=()
	for x in /home; do
		if [[ -d "$x" ]]; then
			all_users+=($(ls "$x"))
		fi
	done
}

#### Setting up bleachbit to run all cleaners, but the swap and writing zeroes
bleach_func() {
	cleaners=($(bleachbit -l | sed '/memory/d' | sed '/free/d'))
	for x in ${cleaners[@]}; do
		echo -e "\n${YELLOW}$x${NOCOLOR}"
		bleachbit -c $x 2>/dev/null
	done
}
#### Start bleachbit GUI for standard users then run the above function for root
run_bleachbit() {
	#### Give some info on the process and then ask for an answer
	clear
	echo -e "${CYAN}We will be using bleachbit as the standard tool for marking directories and files then removing them."
	echo -e "After this is done, we will not rely on bleachbit to overwrite the systems free space for security."
	echo -e "We will instead do it ourselves with the \"dd\" low level byte tool and \"sync\" for journald fs."
	echo -e "${YELLOW}Note: Bleachbit will run in graphical mode for standard users."
	echo -e "${WHITE}Start Bleachbit?\nY/n/e${NOCOLOR}"
	read ans
	#### If the answer is yes then bleachbit will be run by every user listed in the /home directory
	if [[ $ans != "n" ]] && [[ $ans != "e" ]]; then
		for x in ${all_users[@]}; do
			echo -e "\n${WHITE}Starting \"bleachbit\" as user ${YELLOW}\"$x\"${NOCOLOR}"
			if [[ $anything != "n" ]] && [[ $anything != "e" ]]; then
				su $x -c bleachbit 2>/dev/null
				sleep 1
			elif [[ $anything == "n" ]]; then
				break
			elif [[ $anything == "e" ]]; then
				echo "${WHITE}Exiting...${NOCOLOR}"
				sleep 1
				exit 0
			fi
		done
		#### Now it is run again as root
		if [[ $EUID == 0 ]]; then
			echo -e "\n${WHITE}Starting \"bleachbit\" as user ${RED}\"root\"${NOCOLOR}"
			echo -e "${WHITE}Continue?\nY/n/e${NOCOLOR}"
			read anything
			if [[ $anything != "n" ]] && [[ $anything != "e" ]]; then
				echo -e "${WHITE}Run in graphical mode?\ny/N${NOCOLOR}"
				read ans
				if [[ $ans != "y" ]]; then
					bleach_func
				elif [[ $ans == "y" ]]; then
					bleachbit 2>/dev/null
				fi
			elif [[ $anything == "n" ]]; then
				break
			elif [[ $anything == "e" ]]; then
				echo -e "${WHITE}Exiting...${NOCOLOR}"
				sleep 2
				exit 0
			fi
		else
			#### Just in case permissions are lost we then exit
			echo -e "${RED}We lost permissions somewhere... exiting...${NOCOLOR}"
			exit 1
		fi
	elif [[ $ans == "e" ]]; then
		echo -e "${WHITE}Exiting...${NOCOLOR}"
		sleep 1
		exit 0
	elif [[ $ans == "n" ]]; then
		break
	fi
}

partition_display() {
	clear
	echo -e "${YELLOW}Here is what we know about the drives/mounts of your file system..."
	echo -e "${WHITE}================================================================================${NOCOLOR}"
	df -h
	echo -e "${WHITE}================================================================================${NOCOLOR}"
}

zero_file() {
	#### Ask user to type in a path to create a zero file and how many times to do it
	echo -e "${CYAN}\nType in path  as shown under \"Mounted On\""
	echo -e "${WHITE}e/ENTER${NOCOLOR}"
	read path
	if [[ -d $path ]]; then
		echo -e "${CYAN}How many times would you like to overwrite?${NOCOLOR}"
		read overwrite
		while true; do
			if [[ $overwrite -ge 1 ]] && [[ $overwrite -le 10 ]]; then
				break
			else
				read -p "Enter a number from 1 to 10: " overwrite
			fi
		done
	fi
	if [[ $path == "e" ]]; then
		echo -e "${WHITE}Exiting...${NOCOLOR}"
		sleep 1
		exit 1
	elif [[ ! -d $path ]]; then
		echo -e "${WHITE}\"${NOCOLOR}$path${WHITE}\" does not exist... moving on${NOCOLOR}"
	elif [[ -d $path ]]; then
		echo -e "\n${WHITE}Depending on the size of the free space, this action could take quite"
		echo -e "a bit of time. You can press CTRL-C at any time to exit, but you will"
		echo -e "need to remove the zero file manually or restart this script and do a search"
		echo -e "for zero files if you are uncertain about its location."
		echo -e "Your system may become unresponsive during this process, be patient..."
		echo -e "You have chosen \"${YELLOW}$path${WHITE}\""
		echo -e "To be written over \"${YELLOW}$overwrite${WHITE}\" times"
		echo -e "${CYAN}Would you like to continue?${WHITE}\nY/n/e${NOCOLOR}"
		read ans
		if [[ $ans != "n" ]] && [[ $ans != "e" ]]; then
			echo -e "${WHITE}================================================================================"
			#### Uncomment the following to list contents of chosen directory
			#echo -e "Contents of \"${YELLOW}$path${NOCOLOR}\" ${WHITE}are:${NOCOLOR}"
			#ls $path
			count=1
			while [[ $count -le $overwrite ]]; do
				echo -e "\n${YELLOW}Now growing zero file to overwrite free disk space..."
				echo -e "Pass [$count]${NOCOLOR}"
				dd if=/dev/zero of="$path"/zero_file.img
				#### Uncomment the following to list contents of chosen directory
				#echo -e "\n${WHITE}Contents of \"${YELLOW}$path${NOCOLOR}\" ${WHITE}are:${NOCOLOR}"
				#ls $path
				echo -e "\n${YELLOW}Zero file details:${NOCOLOR}"
				file $path/zero_file.img
				let count+=1
			done
			ls -sh $path/zero_file.img
			sleep 1
			echo -e "Now syncing file systems that are journaled i.e. btrfs, ext4"
			echo -e "This will ensure that any copies created by the system will be overwritten, too."
			sleep 1
			# Sync file systems so that journald systems will delete copies
			sync
			echo -e "Now removing zero file..."
			rm $path/zero_file.img
			if [[ $? == 0 ]]; then
				sleep 1
				echo "Removed successfully"
			else
				echo "ERROR: problem removing zero_file.img"
				exit 1
			fi
			sleep 1
			#### Uncomment the following to list the contents of chosen directory
			#echo -e "\n${WHITE}Contents of \"${YELLOW}$path${NOCOLOR}\" ${WHITE}are:${NOCOLOR}"
			#ls $path
			echo -e "${WHITE}================================================================================"
			echo -e "${NOCOLOR}"
		elif [[ $ans == "n" ]]; then
			echo -e "${WHITE}Moving on...\n${NOCOLOR}"
		elif [[ $ans == "e" ]]; then
			echo -e "${WHITE}Exiting...${NOCOLOR}"
			exit 0
		fi
	fi
}

find_zero_files() {
	#### Check for zero file laying around in the system
	echo -e "\n${CYAN}Would you like to search the system for a zero file (zero_file.img)?\n${WHITE}Y/n/e"
	read ans
	if [[ $ans != "n" ]] && [[ $ans != "e" ]]; then
		echo -e "Searching..."
		is_there=$(find / -name zero_file.img 2>/dev/null)
		echo -e "Search completed."
		if [[ "$is_there" ]]; then
			echo -e "Zero file found here: "
			echo -e "$is_there"
			echo -e "Would you like to remove it?\nY/n/e"
			read ans
			if [[ $ans != "e" ]]; then
				echo -e "Retrieving zero files for deletion..."
				find / -name zero_file.img -exec rm {} \;
				echo -e "File removed successfully. Press Enter to continue..."
				read anything
				if [[ ! $? == 0 ]]; then
					echo -e "${RED}There seems to have been an error removing those files!${NOCOLOR}"
				fi
			elif [[ $ans == "e" ]]; then
				echo -e "${WHITE}Exiting...${NOCOLOR}"
				sleep 1
				exit 0
			fi
		elif [[ ! $is_there ]]; then
			echo -e "${WHITE}No zero files found${NOCOLOR}"
		elif [[ $ans == "e" ]]; then
			echo -e "${WHITE}Exiting...${NOCOLOR}"
			sleep 1
			exit 1
		fi
	elif [[ $ans == "e" ]]; then
		echo -e "${WHITE}Exiting...${WHITE}"
		sleep 1
		exit 0
	fi
}

main
