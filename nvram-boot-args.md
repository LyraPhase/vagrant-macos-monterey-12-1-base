# Editing `boot-args` in NVRAM
Default OpenCore boot-args:

    sudo nvram boot-args="-v keepsyms=1 tlbto_us=0 vti=9"

Debugging w/ old-style kernel panics

    sudo nvram boot-args="-v keepsyms=1 tlbto_us=0 vti=9 debug=0x14e"

Note: this did not persist across VM reboot
I actually had to enter this manually into OpenCore `config.plist`

1. Boot into Recovery Mode via OpenCore boot selector
2. Identify & Mount EFI partition

        # Identify the disk + partition marked EFI
        diskutil list
        # Mount EFI partition as MSDOS type (FAT32)
        mkdir /Volumes/EFI
        mount -t msdos /dev/disk0s1 /Volumes/EFI
        # Edit the config.plist
        vi /Volumes/EFI/EFI/OC/config.plist
        # Search for NVRAM -> Add -> 7C436110-AB2A-4BBB-A880-FE41995C9F82
        # Under this XML path, you should find `boot-args` with '-v keepsyms=1 tlbto_us=0 vti=9' value
        # Changed to:
        -v keepsyms=1 tlbto_us=0 vti=9 debug=0x14e

This persists across reboots thanks to OpenCore

