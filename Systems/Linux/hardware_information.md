# Hardware Information
## General
* `sudo lshw` - general hardware details
  * `-C [CLASS]` - specify a specific category of hardware
* `inxi -Fxz` - general hardware details
  * `-F` : full output
  * `-x` : adds details
  * `-z` : masks personally identifying information, like MAC and IP addresses
## CPU
* `lscpu` - CPU details
## Memory
* `sudo dmidecode -t memory` - memory details 
* `free -mh` - shows memory and swap memory usage in human readable format
## USB & PCI Buses
* `lspci` - shows pci information on controllers
  * find a controller you are interested, and then grep for its device number for all details on that device
* `lsusb` - shows USB buses
## Disk
* `lsblk` - lists all disks with their defined partitions along with their size
* `sudo fdisk -l` - includes number of sectors, size, filesystem ID and type, start and end sectors of partitions
* `sudo blkid` - lists UUID, TYPE, and PARTUUID of partitions
* `df -h` - list the mounted filesystems, mount points, and space used and available for each

## Display details
* `xdpyinfo | grep 'dimensions:'`

## Low-Level Software
* `dmidecode -t bios` - UEFI/BIOS date and version, and available characteristics
* `uname -a` - all kernel information