##regdefs
A framework providing a compact way of specifying registers, including addresses, groupings of registers into devices (and unions of sub-groupings...analogous to C structs and unions), and the various flags and bitfields they contain. The specification can then be used to do a number of things, such as generate a C include file or documentation, or interactively work with a device through a Pry or IRB console and some code to remotely set and read registers.

The main benefit is the compact and clear specification DSL. Registers are specified in a simple and clear fashion that can more easily be reviewed and checked for errors, more easily be written without introducing errors, and which can then be used to generate a much longer include file, with bit masks, offsets, bitfields, structs, and so on as desired. In the case of the LPC1343, the resulting include file is nearly 8 times the size of the register specification, containing a large amount of redundant information that would otherwise either have to be omitted or maintained separately.

The regdefs_genheaders.rb tool will generate a C header for a given part. Run without any parameters to get usage and a list of supported parts.


##lpcprog
The LPC1343 microcontroller has a ROM bootloader that emulates a USB mass storage device, showing up as a flash drive with a single firmware file when mounted. However, it is particular about the way the firmware file is written, and simply copying the file does not work on OS X and Linux. Also, the bootloader will reject the checksums that GCC produces.

This script will fix the checksums, pad the file to the correct length, and write it in a way the bootloader accepts, overwriting the original file instead of replacing the file. It currently works on Mac OS X, Linux and Windows support are partially implemented.

Installation: Put lpcprog.rb somewhere covered by your executable search paths, renaming to lpcprog or creating a symlink with that name.

Usage: `lpcprog FIRMWARE_BINARY`


##usbtools
usbtools/usbdesc.rb is similarly a library for specifying USB descriptors with a simple and readable syntax, automatically handling things like computing sizes. An example of its use is in examples/usbtools/usbdesc.rb.

There is a single `Descriptor` class that takes a descriptor type and a block in which the descriptor fields can be set. An error will be produced if an attempt is made to set a field that doesn't exist for that descriptor type, and the size and type fields are set automatically. Order does not matter, the order in the `fields` hash of the descriptor type is always used. There are currently no default values, all fields other than bLength, wTotalLength, and bDescriptorType must be specified.

examples/usbcon.cpp and examples/usbcon.rb are simple starting points for working with libusb.