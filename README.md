# hillary
My dirty bash script Hillary should've used ;)

Make the file executable then run as root

It will check for dependencies needed to run, then will start off by displaying memory info.
You can choose to clean cache with 3 options.

Next it will give you the option to run bleachbit to help identify places where info may be hidden
from you for deletion

Next it will display the mounted partitions on your system and give you an option to overwrite them
with zeroes after you have ran bleachbit and made your deletions

Because of more modern file systems that have a shadow i.e. btrfs and ext4 the script will sync everything
before overwriting to ensure there are no copies lying around

You can choose how many times to overwrite, but once is typically enough. Depending on the size of the
partition you have chosen, it may take a while.

Basically, we are creating a file 512b at a time with the dd command to fill all the empty space on the
partition until it is full to ensure that all files that were flagged by deletion are overwritten

After the file is as large as it can be it will then be deleted as well, but now only zeroes can be recovered

If you cancel or the script is interupted for any reason, I have included a find command to get the file
that was created so it can be deleted to free up space. It is the last part of the script to run so don't
worry if you forgot where which partition you instructed the script to zero out

All contributions welcome.
