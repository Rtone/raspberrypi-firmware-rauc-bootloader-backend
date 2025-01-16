# raspberrypi-firmware-rauc-bootloader-backend

An implementation of a RAUC custom bootloader backend for the Raspberry Pi
firmware.

## DESCRIPTION

The Raspberry Pi firmware supports fail-safe OS updates with A/B booting thanks
to the optional configuration file [autoboot.txt] and the one-shot reboot flag
[tryboot].

Unlike the [U-Boot] and [Barebox] bootloader backends, the custom bootloader
backend for the Raspberry Pi firmware cannot implement a boot-attempts counter.
Its one-shot reboot flag is very similar to the EFI variable `BootNext` of the
[EFI] bootloader backend. It is like an implementation `boot-attempts` counter
of 1 after an update.

_Important_: The firmware cannot fallback to the other slot if the primary slot
gets unbootable for some reason.

The Raspberry Pi firmware RAUC custom bootloader backend parses and updates the
file `autoboot.txt` in the first partition. It gets the one-shot reboot flag
set by the firmware to the device-tree blob node `/chosen/bootloader/partition`
at boot thanks to the utility `fdtget`, or it sets it down to the firmware for
the next boot thanks to the utility [vcmailbox].

It implements the four mandatory actions:
 - get the primary slot
 - set the primary slot
 - get the boot state
 - set the boot state

And it implements the optional action: get the current booted slot.

_Note_: The custom bootloader backend APIs for the Raspberry Pi firmware are
self-documented in the shell [backend] script.

## TRYBOOT

The online documentation for [tryboot] tells to set the one-shot flag in the
`reboot` command as below:

	# Quotes are important. Reboot only accepts a single argument.
	sudo reboot '0 tryboot'

The kernel of the [Raspberry Pi hardwares] forwards the optional [reboot]
argument given to [reboot(2)] to the [raspberrypi firmware driver] before the
system is restarted. The driver submits the mailbox tag to the VPU firmware
through the [mailbox property interface].

It is highly undesirable to trigger a `reboot` from within RAUC to set the new
boot state. The firmware utility [vcmailbox] submits from the userspace thanks
to the [broadcom vcio driver] instead.

_Note_: The tag **Set Reboot Flags** is undocumented; The [commit] in the linux
kernel tree reveals it as:

```
#### Set reboot flags

 * Tag: 0x00030064
 * Request:
   * Length: 4
   * Value:
     * u32: flags
 * Response:
   * Length: 0
   * Value:
```

## CONFIGURATION FILES

### SYSTEM.CONF

The RAUC file [system.conf] **MUST** set the attribute `bootloader` to `custom`
in the section `system`, **AND** the attribute `bootloader-custom-backend` to
the location of the custom bootloader backend in the section `handlers`.

For example; if the backend is at `/usr/lib/rauc/backend/raspberrypi-firmware`:

	[system]
	# (...)
	bootloader=custom
	
	[handlers]
	# (...)
	bootloader-custom-backend=/usr/lib/rauc/backend/raspberrypi-firmware

Furthermore, the file **MUST** define the rootfs slots **AND** their firmware
slots in multiple sections `slot`; the firmware slots have to be bounded to
their rootfs slots using the attribute `parent` instead of having the attribute
`bootname` set.

For example; if the partition table is MBR, with the first partition containing
the [autoboot.txt] file, with the next two following partitions containing the
firmware files, and with the fourth and last partition is an extended partition
containings the two rootfs partitions:

	[slot.firmware.0]
	device=/dev/mmcblk0p2
	type=vfat
	parent=rootfs.0
	
	[slot.firmware.1]
	device=/dev/mmcblk0p3
	type=vfat
	parent=rootfs.1
	
	[slot.rootfs.0]
	device=/dev/mmcblk0p5
	type=ext4
	bootname=ROOTFS-A
	
	[slot.rootfs.1]
	device=/dev/mmcblk0p6
	type=ext4
	bootname=ROOTFS-B

### AUTOBOOT.TXT

The Raspberry Pi firmware file [autoboot.txt] **MUST** be located at path
`/boot/autoboot.txt`; i.e. the partition containing that file has to be mounted
to `/boot`.

For example; if booting from SD-card and using [fstab(5)]:

	# <device>      <mount point>  <type> <options> <dump>  <pass>
	/dev/mmcblk0p1  /boot          vfat   rw        0       0

### IMPORTANT

The firmware block devices **MUST** be coherent in both files [system.conf] and
[autoboot.txt]; i.e. the firmware partition numbers in `boot_partition` have to
match the ones defined in the slot sections.

For example; if the primary slot is `slot.rootfs.0`, and if the partition table
in the one defined in the [example](#systemconf) above:

	[all]
	tryboot_a_b=1
	boot_partition=2
	[tryboot]
	boot_partition=3

## REQUIREMENTS

### BASH

The [Bourne Again shell] since the custom bootloader backend is a shell script
using several bashism (such as `bash` arrays, the compound command `[[`, or the
binary operator `=~`).

_Important_: The [backend] is written in pure [bash(1)].

### FDTGET

The device-tree compiler [fdtget] utility to read the bootloader values from
the device-tree.

### VCMAILBOX

The Raspberry Pi [vcmailbox] utility to set the one-shot reboot flag [tryboot].

### VCIO DRIVER

The downstream Raspberry Pi [broadcom vcio driver] to let the [vcmailbox]
utility to drive the mailbox interface to VideoCore.

_Important_: The driver is not supported upstream.

## KERNEL UPDATES

The kernel updates through the installation of the firmware slots require an
installation [hook] in the bundle to include the appropriate kernel parameter
`root=` in the file `cmdline.txt`. More information are given in that [change].

_Note_: The kernel updates are doable using installation [handlers] in the root
filesystem as well.

## NATIVE BOOTCHOOSER IMPLEMENTATION

The native bootchooser implementation in the RAUC tree is on its way.

## EXAMPLE

The three files [system.conf-pi4], [autoboot.txt-a] and [hook.bash] in the
directory `support` provide an example of a RAUC Raspberry Pi 4 Model B.

	install -D -m0644 support/system.conf-pi4 /etc/rauc/system.conf
	install -D -m0644 support/autoboot.txt-a /boot/autoboot.txt

_Note_: Set the following lines to the RAUC manifest file to enable for kernel
updates, and create the bundle then:

	[update]
	compatible=raspberrypi,4-model-b
	# (...)
	
	[hooks]
	filename=support/hook.bash
	
	[image.rootfs]
	# (...)
	hooks=pre-install
	
	[image.firmware]
	# (...)
	hooks=post-install

## INSTALL

Run the following command to install *bootloader-custom-backend(1)*,
*system-info(1)* and *rauc-mark-good.service(8)*

	$ sudo make install

Traditional variables *DESTDIR* and *PREFIX* can be overridden

	$ sudo make install PREFIX=/opt/raspberrypi-firmware-rauc-bootloader-backend

Or

	$ make install DESTDIR=$PWD/pkg PREFIX=/usr

## EMBEDDED BUILD SYSTEMS

A [Buildroot package] is available in the br2-external [rtone-br2-external] and
a [Bitbake recipe] is available in the layer [meta-downstream].

## PATCHES

Sumbit patches at <https://github.com/Rtone/raspberrypi-firmware-rauc-bootloader-backend/pulls>

## BUGS

Report bugs at <https://github.com/Rtone/raspberrypi-firmware-rauc-bootloader-backend/issues>

## AUTHOR

Written by Gaël PORTAY *gael.portay@rtone.fr*

## COPYRIGHT

Copyright 2024-2025 Gaël PORTAY

Copyright 2024-2025 Rtone

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 2.1 of the License, or (at your option) any
later version.

## SEE ALSO

[bash(1)], [fdtget], [vcmailbox(1)]

[Barebox]: https://rauc.readthedocs.io/en/latest/integration.html#barebox
[Bitbake recipe]: https://github.com/gportay/meta-downstream/blob/master/meta-rauc-raspberrypi-firmware/recipes-bsp/raspberrypi-firmware-rauc-bootloader-backend/raspberrypi-firmware-rauc-bootloader-backend_git.bb
[Bourne Again shell]: https://www.gnu.org/software/bash/
[Buildroot package]: https://github.com/Rtone/rtone-br2-external/tree/main/package/raspberrypi-firmware-systemd-generator
[EFI]: https://rauc.readthedocs.io/en/latest/integration.html#efi
[Raspberry Pi hardwares]: https://www.raspberrypi.com/products/
[U-Boot]: https://rauc.readthedocs.io/en/latest/integration.html#id5
[autoboot.txt-a]: support/autoboot.txt-a
[autoboot.txt]: https://www.raspberrypi.com/documentation/computers/config_txt.html#autoboot-txt
[backend]: bootloader-custom-backend
[bash(1)]: https://linux.die.net/man/1/bash
[broadcom vcio driver]: https://github.com/raspberrypi/linux/blob/rpi-6.6.y/drivers/char/broadcom/vcio.c
[change]: https://github.com/Rtone/rtone-br2-external/commit/9ba8d9b3df9584e50cf5ae6952af54417a86b3f3
[commit]: https://github.com/raspberrypi/linux/commit/777a6a08bcf8f5f0a0086358dc66d8918a0e1c57#diff-1c6051b88ea21684666367f31afc5452e51abc9fe5f340281cd9d38459ac3d35R224-R225
[custom]: https://rauc.readthedocs.io/en/latest/integration.html#custom
[fdtget(1)]: https://linux.die.net/man/1/fdtget
[fdtget]: https://git.kernel.org/pub/scm/utils/dtc/dtc.git/tree/fdtget.c
[fstab(5)]: https://linux.die.net/man/5/fstab
[handlers]: https://rauc.readthedocs.io/en/latest/using.html#system-based-customization-handlers
[hook.bash]: support/hook.bash
[hook]: https://rauc.readthedocs.io/en/latest/using.html#bundle-based-customization-hooks
[linux]: https://github.com/raspberrypi/linux/commit/777a6a08bcf8f5f0a0086358dc66d8918a0e1c57#diff-1c6051b88ea21684666367f31afc5452e51abc9fe5f340281cd9d38459ac3d35R224-R225
[mailbox property interface]: https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface
[meta-downstream]: https://www.portay.io/meta-downstream
[meta-rauc-raspberrypi-firmware]: https://github.com/gportay/meta-downstream/blob/master/meta-rauc-raspberrypi-firmware
[raspberrypi firmware driver]: https://github.com/raspberrypi/linux/blob/rpi-6.6.y/drivers/firmware/raspberrypi.c
[reboot(2)]: https://linux.die.net/man/2/reboot
[reboot]: https://www.freedesktop.org/software/systemd/man/latest/systemctl.html#reboot
[rtone-br2-external]: https://rtone.github.io/rtone-br2-external
[system.conf-pi4]: support/system.conf
[system.conf]: https://rauc.readthedocs.io/en/latest/reference.html#sec-ref-slot-config
[tryboot]: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot
[vcmailbox(1)]: https://linux.die.net/man/1/vcmailbox
[vcmailbox]: https://github.com/raspberrypi/utils/blob/master/vcmailbox/vcmailbox.c
