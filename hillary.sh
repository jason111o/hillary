#!/usr/bin/env bash
#### Written by Jason Pippin

#### Please set versioning before submitting changes ####
version="hillary-2.1"

#### Pass some time graphically while searching for helper files
echo $version
#### Find and set the helper files
echo -e "Searching for helper files..."
count=20
while [ $count -gt 0 ]; do
  sleep 0.25
  echo -n " *"
  count=$((count-1))
done &
source $(find / -name "hillary_functions" 2>/dev/null)
source $(find / -name hillary_style 2>/dev/null)
echo ""

######################################Main######################################
check_su
check_for_dependencies
dependencies_needed
while true; do
  free_cache
  run_bleachbit
  zero_file
  find_zero_files
done
################################################################################
