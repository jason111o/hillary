#!/usr/bin/env bash
#### Written by Jason Pippin

#### Please set versioning before submitting changes ####
version="hillary-3.2"
creator="Jason Pippin"

######################################Main######################################
#### I use this function for pure readability. main() is the last thing run in
#### this script
function main() {
  print_version
  check_su
  check_for_dependencies
  dependencies_needed
  while true; do
    free_cache
    run_bleachbit
    zero_file
    find_zero_files
  done
}
################################################################################

##### Add a little style
RED='\033[01;31m'
YELLOW='\033[01;33m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
NOCOLOR='\033[0m'

#### Check for super powers
check_su() {
  if [[ $EUID != 0 ]]; then
    echo -e "${WHITE}You do not have super powers!${NOCOLOR}"
    sleep 1
    exit 1
  fi
}

#### Define all the functions for main() ####
#### Check for dependencies
check_for_dependencies() {
  depends=("sudo" "sleep" "bleachbit" "dd" "free" "sync" "find" "command" "df" "echo")
  depends_not_installed=()
  echo -e "Checking dependencies"
  for x in "${depends[@]}"; do
    echo -n " *"
    xpath=$(command -v "$x")
    if [[ "$xpath" ]]; then
      sleep .5
    elif [[ ! "$xpath" ]]; then
      sleep 0.25
      depends_not_installed+=("$x")
    fi
  done
  sleep 1
}
#### If dependencies are needed then prompt the user to install them
dependencies_needed() {
  len=${#depends_not_installed}
  while [ "$len" -gt 0 ]; do
    echo ""
    echo -e "${WHITE}Install missing dependencies? Y/n/e/v${NOCOLOR}"
    read -r ans
    if [[ "$ans" == "v" ]]; then
      print_version
    elif [[ "$ans" == "n" ]]; then
      echo -e "${CYAN}This script needs..."
      for x in "${depends_not_installed[@]}"; do
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
    else
      for x in "${depends_not_installed[@]}"; do
        apt install "$x"
        if [[ $? != 0 ]]; then
          echo -e "${YELLOW}\"$x\" was not found in your distribution package sources."
          echo -e "Check your distros documentation.${NOCOLOR}\n"
        fi
        check_for_dependencies
        len=${#depends_not_installed}
        if [[ $len == 0 ]]; then
          echo -e "${WHITE}Dependencies have been satisfied. Press enter to continue...${NC}"
        fi
      done
    fi
  done
}
#### Display memory use and clear cache if the user chooses so
free_cache() {
  clear
  echo -e "${YELLOW}Current memory stat:${NOCOLOR}"
  free -h
  echo -e "${CYAN}Would you like to free memory/caches?${WHITE}\nY/n/e/v${NOCOLOR}"
  read -r ans
  if [[ $ans == "v" ]]; then
    print_version
    free_cache
  elif [[ $ans == "n" ]]; then
    return
  elif [[ $ans == "e" ]]; then
    echo -e "${WHITE}Exiting...${NOCOLOR}"
    sleep 1
    exit 0
  else
    drop_caches_path=$(find /proc -name drop_caches 2>/dev/null)
    echo -e "${YELLOW}Applications/Programs may start slower after cleaning as the system resumes new cache creations."
    echo -e "${WHITE}1. Free page cache"
    echo -e "2. Free reclaimable slab objects (includes dentries and inodes)"
    echo -e "3. Free page cache and slab objects\n1/2/3/n${NOCOLOR}"
    read -r num
    while true; do
      if [[ $num != 1 ]] && [[ $num != 2 ]] && [[ $num != 3 ]] && [[ $num != "n" ]]; then
        echo -e "${YELLOW}You must enter a 1, 2, or 3 for cache or \"n\" to continue.${NOCOLOR}"
        echo -e "${WHITE}1/2/3/n${NOCOLOR}"
        read -r num
      elif [[ $num == 1 ]] || [[ $num == 2 ]] || [[ $num == 3 ]]; then
        # sync the system before clearing cache
        sync
        echo "$num" >"$drop_caches_path"
        sleep 1
        echo -e "${YELLOW}New memory stat:${NOCOLOR}"
        free -h
        echo -e "\n${CYAN}Press ENTER to continue.${NOCOLOR}"
        read -r
        break
      elif [[ $num == "n" ]]; then
        break
      else
        exit 1
      fi
    done
  fi
}
#### Setting up bleachbit to run all cleaners, but the swap and writing zeroes
bleach_func() {
  mapfile -t cleaners < <(bleachbit -l | sed '/memory/d' | sed '/free/d')
  for x in "${cleaners[@]}"; do
    echo -e "\n${YELLOW}$x${NOCOLOR}"
    bleachbit -c "$x" 2>/dev/null
  done
}
#### Start bleachbit GUI for standard users then run the above function for root
run_bleachbit() {
  #### Set all users whom have a home directory to an array
  all_users=()
  mapfile -t all_users < <(ls /home/)
  #### Give some info on the process and then ask for an answer
  clear
  echo -e "${CYAN}We will be using bleachbit as the standard tool for marking directories and files then removing them."
  echo -e "After this is done, we will not rely on bleachbit to overwrite the systems free space for security."
  echo -e "We will instead do it ourselves with the \"dd\" low level byte tool and \"sync\" for journald fs."
  echo -e "${YELLOW}Note: Bleachbit will only run in graphical mode for standard users."
  echo -e "${WHITE}Start Bleachbit?\nY/n/e/v${NOCOLOR}"
  read -r ans
  #### If the answer is yes then bleachbit will be run by every user listed in the /home directory
  if [[ $ans == "v" ]]; then
    print_version
    run_bleachbit
  elif [[ $ans == "e" ]]; then
    echo -e "${WHITE}Exiting...${NOCOLOR}"
    sleep 1
    exit 0
  elif [[ $ans == "n" ]]; then
    return
  else
    #### Double check for super powers and start bleachbit as each user found in the /home directory
    if [[ $EUID == 0 ]]; then
      for x in "${all_users[@]}"; do
        echo -e "\n${WHITE}Starting \"bleachbit\" as user ${YELLOW}\"$x\"${NOCOLOR}"
        sleep 1
        su "$x" -c bleachbit 2>/dev/null
      done
      echo -e "\n${WHITE}Starting \"bleachbit\" as user ${RED}\"root\"${NOCOLOR}"
      echo -e "${WHITE}Continue?\nY/n/e/v${NOCOLOR}"
      read -r ans
      if [[ $ans == "v" ]]; then
        # print version and start over
        print_version
        run_bleachbit
      elif [[ $ans == "n" ]]; then
        return
      elif [[ $ans == "e" ]]; then
        echo -e "${WHITE}Exiting...${NOCOLOR}"
        sleep 2
        exit 0
      else
        echo -e "${WHITE}Run in graphical mode?\nY/n${NOCOLOR}"
        read -r ans
        if [[ $ans == "n" ]] || [[ $ans == "N" ]]; then
          bleach_func
        else
          bleachbit 2>/dev/null
        fi
      fi
    else
      #### Just in case permissions are lost we then exit
      echo -e "${RED}We lost permissions somewhere... exiting...${NOCOLOR}"
      exit 1
    fi
  fi
}
### This here is how we gonna overwrite deleted files and free space
zero_file() {
  clear
  #### Ask user to type in a path to create a zero file and how many times to do it
  echo -e "${CYAN}Select a path for overwriting free space and deleted data"
  echo -e "1. /home [Default]\n2. /root\n3. /\n4. Enter path manually${NOCOLOR}"
  read -r -p "Enter your selection: " selection
  if [[ $selection == "1" ]]; then
    path=/home
  elif [[ $selection == "2" ]]; then
    path=/root
  elif [[ $selection == "3" ]]; then
    path=/
  elif [[ $selection == "4" ]]; then
    echo -e "\n${YELLOW}Here is a list of mounted file systems...\n${NOCOLOR}"
    df -hT
    echo -e "\n${RED}WARNING: With great power comes great responsibility!${NOCOLOR}"
    read -r -p "Type in the path now: " ans
    # clean up the last slash if entered
    if [[ $ans == "/" ]]; then
      path=/
    else
      path=$(sed 's:/*$::' < <(echo "$ans"))
    fi
  elif [[ $selection == "e" ]] || [[ $selection == "E" ]]; then
    echo -e "${WHITE}Exiting...${NOCOLOR}"
    sleep 1
    exit 0
  else
    path=/home
    echo "Going with the default... \"$path\""
    sleep 1
  fi
  if [[ -d $path ]]; then
    echo -e "${CYAN}How many times would you like to overwrite?${NOCOLOR}"
    read -r overwrite
    while true; do
      if [[ $overwrite -ge 1 ]] && [[ $overwrite -le 10 ]]; then
        break
      elif [[ $overwrite == 0 ]]; then
        return
      else
        read -r -p "Enter a number from 1 to 10 to continue or 0 to skip: " overwrite
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
    echo -e "${CYAN}Would you like to continue?${WHITE}\nY/n/e/v${NOCOLOR}"
    read -r ans
    if [[ $ans == "v" ]]; then
      print_version
    elif [[ $ans == "n" ]]; then
      echo -e "${WHITE}Moving on...\n${NOCOLOR}"
    elif [[ $ans == "e" ]]; then
      echo -e "${WHITE}Exiting...${NOCOLOR}"
      exit 0
    else
      echo -e "${WHITE}================================================================================"
      #### Uncomment the following to list contents of chosen directory
      #echo -e "Contents of \"${YELLOW}$path${NOCOLOR}\" ${WHITE}are:${NOCOLOR}"
      #ls $path
      count=1
      while [[ $count -le $overwrite ]]; do
        echo -e "\n${YELLOW}Now growing zero file to overwrite free disk space..."
        echo -e "Pass [$count]${NOCOLOR}"
        dd if=/dev/zero of="$path"/zero.file status=progress
        #### Uncomment the following to list contents of chosen directory
        #echo -e "\n${WHITE}Contents of \"${YELLOW}$path${NOCOLOR}\" ${WHITE}are:${NOCOLOR}"
        #ls $path
        echo -e "\n${YELLOW}Zero file details:${NOCOLOR}"
        file "$path"/zero.file
        count=$((count + 1))
      done
      ls -sh "$path"/zero.file
      sleep 1
      echo -e "Now syncing file systems that are journaled i.e. btrfs, ext4"
      echo -e "This will ensure that any copies created by the system will be overwritten, too."
      sleep 1
      # Sync file systems so that journald systems will delete copies
      sync
      echo -e "Now removing zero file..."
      rm "$path"/zero.file
      if [[ $? == 0 ]]; then
        sleep 1
        echo "Removed successfully"
      else
        echo "ERROR: problem removing zero.file"
        exit 1
      fi
      sleep 1
      #### Uncomment the following to list the contents of chosen directory
      #echo -e "\n${WHITE}Contents of \"${YELLOW}$path${NOCOLOR}\" ${WHITE}are:${NOCOLOR}"
      #ls $path
      echo -e "${WHITE}================================================================================"
      echo -e "${NOCOLOR}"
    fi
  fi
}
### Locate zero files that need deleting/removing/shredding
find_zero_files() {
  #### Check for zero file laying around in the system
  echo -e "\n${CYAN}Would you like to search the system for a zero file (zero.file)?\n${WHITE}Y/n/e/v"
  read -r ans
  if [[ $ans == "v" ]]; then
    print_version
    clear
    find_zero_files
  elif [[ $ans == "e" ]]; then
    echo -e "${WHITE}Exiting...${WHITE}"
    sleep 1
    exit 0
  elif [[ $ans == "n" ]]; then
    return
  else
    echo -e "Searching..."
    is_there=$(find / -name zero.file 2>/dev/null)
    echo -e "Search completed."
    if [[ "$is_there" ]]; then
      echo -e "Zero file found: ${RED}$is_there${WHITE} "
      echo -e "Would you like to remove it?\nY/n/e"
      read -r ans
      if [[ $ans != "e" ]] && [[ $ans != "n" ]]; then
        echo -e "Retrieving zero files for deletion..."
        find / -name zero.file -exec rm {} \; 2>/dev/null
        echo -e "\nFile removed successfully. Press Enter to continue..."
        read -r
        if [[ ! $? == 0 ]]; then
          echo -e "${RED}There seems to have been an error removing those files!${NOCOLOR}"
        fi
      elif [[ $ans == "n" ]]; then
        echo -e "${WHITE}Moving on...\n${NOCOLOR}"
      elif [[ $ans == "e" ]]; then
        echo -e "${WHITE}Exiting...${NOCOLOR}"
        sleep 1
        exit 0
      fi
    elif [[ ! $is_there ]]; then
      echo -e "${WHITE}No zero files found${NOCOLOR}"
      echo -e "\nPress ENTER to continue"
      read -r
    elif [[ $ans == "e" ]]; then
      echo -e "${WHITE}Exiting...${NOCOLOR}"
      sleep 1
      exit 1
    fi
  fi
}
### Print the current script version
print_version() {
  echo -e "\n${YELLOW}$version\nCreated By: $creator${NOCOLOR}\n"
  sleep 2
}

#### Run main()
main