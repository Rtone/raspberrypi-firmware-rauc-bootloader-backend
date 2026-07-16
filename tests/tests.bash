#!/bin/bash
#
# Copyright 2025-2026 Gaël PORTAY
#
# SPDX-License-Identifier: LGPL-2.1-or-later
#

set -e
set -o pipefail

run() {
	lineno="${BASH_LINENO[0]}"
	test="$*"
	echo -e "\e[1mRunning $test...\e[0m"
}

ok() {
	ok=$((ok+1))
	echo -e "\e[1m$test: \e[32m[OK]\e[0m"
}

ko() {
	ko=$((ko+1))
	echo -e "\e[1m$test: \e[31m[KO]\e[0m"
	reports+=("$test at line \e[1m$lineno \e[31mhas failed\e[0m!")
	if [[ $EXIT_ON_ERROR ]]
	then
		exit 1
	fi
}

fix() {
	fix=$((fix+1))
	echo -e "\e[1m$test: \e[34m[FIX]\e[0m"
	reports+=("$test at line \e[1m$lineno is \e[34mfixed\e[0m!")
}

bug() {
	bug=$((bug+1))
	echo -e "\e[1m$test: \e[33m[BUG]\e[0m"
	reports+=("$test at line \e[1m$lineno is \e[33mbugged\e[0m!")
}

result() {
	exitcode="$?"
	trap - 0

	echo -e "\e[1mTest report:\e[0m"
	for report in "${reports[@]}"
	do
		echo -e "$report" >&2
	done

	if [[ $ok ]]
	then
		echo -e "\e[1m\e[32m$ok test(s) succeed!\e[0m"
	fi

	if [[ $fix ]]
	then
		echo -e "\e[1m\e[34m$fix test(s) fixed!\e[0m" >&2
	fi

	if [[ $bug ]]
	then
		echo -e "\e[1mWarning: \e[33m$bug test(s) bug!\e[0m" >&2
	fi

	if [[ $ko ]]
	then
		echo -e "\e[1mError: \e[31m$ko test(s) failed!\e[0m" >&2
	fi

	if [[ $exitcode -ne 0 ]] && [[ $ko ]]
	then
		echo -e "\e[1;31mExited!\e[0m" >&2
	elif [[ $exitcode -eq 0 ]] && [[ $ko ]]
	then
		exit 1
	fi

	exit "$exitcode"
}

RAUC_SYSTEM_CONF="system.conf"
export RAUC_SYSTEM_CONF

PATH="$PWD:$PATH"
trap result 0 SIGINT

rm -f /tmp/00038064
cp autoboot.txt-a /tmp/autoboot.txt

# get-primary
#
# To get the primary slot, the handler is called with the argument get-primary.
# The handler must output the current primary slot’s bootname on the stdout,
# and return 0 on exit, if no error occurred. In case of failure, the handler
# must return with non-zero value.

run "get-primary reports the boot_partition from section [all] in autoboot.txt if undefined slot is booted"
if bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^2$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [all] in autoboot.txt if primary slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^2$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [all] in autoboot.txt if primary slot is booted and the tryboot flag is set"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^2$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [all] in autoboot.txt if other slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^2$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [all] in autoboot.txt if other slot is booted and the tryboot flag is set"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^2$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [tryboot] in autoboot.txt if undefined slot is booted and if reboot flag is set"
if VCMAILBOX_00030064=1 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [tryboot] in autoboot.txt if primary slot is booted and if reboot flag is set"
if VCMAILBOX_00030064=1 \
   FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [tryboot] in autoboot.txt if primary slot is booted and the tryboot and reboot flags are set"
if VCMAILBOX_00030064=1 \
   FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [tryboot] in autoboot.txt if other slot is booted and if reboot flag is set"
if VCMAILBOX_00030064=1 \
   FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo

run "get-primary reports the boot_partition from section [tryboot] in autoboot.txt if other slot is booted and the tryboot and reboot flags are set"
if VCMAILBOX_00030064=1 \
   FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-primary | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo

# set-primary
#
# Accordingly, in order to set the primary slot, the custom bootloader handler
# is called with argument set-primary <slot.bootname> where <slot.bootname>
# matches the bootname= key defined for the respective slot in your
# system.conf. If the set was successful, the handler must also return with a
# 0, otherwise the return value must be non-zero.

run "set-primary keeps the reboot flag unchanged if the primary slot is marked as primary"
if bootloader-custom-backend set-primary 2 && \
   ! test -e /tmp/00038064
then
	ok
else
	ko
fi
echo

run "set-primary keeps the reboot flag if the other slot is marked as primary and if the reboot flag is set"
if VCMAILBOX_00030064=1 \
   bootloader-custom-backend set-primary 3 && \
   ! test -e /tmp/00038064
then
	ok
else
	ko
fi
echo

run "set-primary clears the reboot flag if the primary slot is marked as primary and if the reboot flag is set"
if VCMAILBOX_00030064=1 \
   bootloader-custom-backend set-primary 2 && \
   grep "^0x0000001c 0x80000000 0x00038064 0x00000004 0x80000004 0x00000000 0x00000000$" /tmp/00038064
then
	ok
else
	ko
fi
# restore setup
rm /tmp/00038064
echo

run "set-primary sets the reboot flag if the primary slot is marked as primary and if the reboot flag is set"
if bootloader-custom-backend set-primary 3 && \
   grep "^0x0000001c 0x80000000 0x00038064 0x00000004 0x80000004 0x00000001 0x00000000$" /tmp/00038064
then
	ok
else
	ko
fi
# restore setup
rm /tmp/00038064
echo

# get-state
#
# RAUC must be able to determine the boot state of a specific slot. RAUC
# determines the necessary boot state by calling the custom bootloader handler
# with the argument get-state <slot.bootname>. Whereupon the handler has to
# output the state good or bad to stdout and exit with the return value 0. If
# the state cannot be determined or another error occurs, the custom bootloader
# handler must exit with non-zero return value.

run "get-state fails if slot is not defined in /etc/rauc/system.conf"
if ! bootloader-custom-backend get-state 0
then
	ok
else
	ko
fi
echo

run "get-state reports the primary slot as good if the primary slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=0 \
   bootloader-custom-backend get-state 2 | tee /dev/stderr | grep -q '^good$'
then
	ok
else
	ko
fi
echo

run "get-state reports the primary slot as good if the primary slot is booted even if the tryboot flag is set"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-state 2 | tee /dev/stderr | grep -q '^good$'
then
	ok
else
	ko
fi
echo

run "get-state reports the primary slot as bad if the other slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   bootloader-custom-backend get-state 2 | tee /dev/stderr | grep -q '^bad$'
then
	ok
else
	ko
fi
echo

run "get-state reports the primary slot as bad if the other slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-state 2 | tee /dev/stderr | grep -q '^bad$'
then
	ok
else
	ko
fi
echo

# set-state
#
# To set the boot state to the desire slot, the handler is called with argument
# set-state <slot.bootname> <state>. As already mentioned in the get-state
# comment above, the <slot.bootname> matches the bootname= key defined for the
# respective slot in your system.conf. The <state> argument corresponds to one
# of the following values:
# - good if the last start of the slot was successful or
# - bad if the last start of the slot failed.
# The return value must be 0 if the boot state was set successfully, or
# non-zero if an error occurred.

run "set-state fails if slot is not defined in /etc/rauc/system.conf"
if ! bootloader-custom-backend set-state 0 good && \
   ! bootloader-custom-backend set-state 0 bad 
then
	ok
else
	ko
fi
echo

run "set-state ignores if the slot is marked as bad"
if bootloader-custom-backend set-state 2 bad && \
   diff /tmp/autoboot.txt autoboot.txt-a
then
	ok
else
	ko
fi
echo

run "set-state ignores if the slot is marked as bad, even if the slot is the other slot"
if bootloader-custom-backend set-state 3 bad && \
   diff /tmp/autoboot.txt autoboot.txt-a
then
	ok
else
	ko
fi
echo

run "set-state keeps the autoboot.txt unchanged if the slot is marked as good and if the tryboot flag is unset"
if FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=0 \
   bootloader-custom-backend set-state 2 good && \
   diff /tmp/autoboot.txt autoboot.txt-a
then
	ok
else
	ko
fi
echo

run "set-state keeps the autoboot.txt unchanged if the slot is marked as good and if the tryboot flag is unset, even if the slot is the other slot"
if FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=0 \
   bootloader-custom-backend set-state 3 good && \
   diff /tmp/autoboot.txt autoboot.txt-a
then
	ok
else
	ko
fi
echo

run "set-state keeps the autoboot.txt unchanged if the slot is marked as good and if the tryboot flag and the reboot flag are set"
if FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   VCMAILBOX_00030064=1 \
   bootloader-custom-backend set-state 3 good && \
   diff /tmp/autoboot.txt autoboot.txt-a
then
	ok
else
	ko
fi
echo

run "set-state swaps the boot_partition in autoboot.txt if the other slot is marked as good and if the tryboot flag is set"
if FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   VCMAILBOX_00030064=0 \
   bootloader-custom-backend set-state 3 good && \
   diff /tmp/autoboot.txt autoboot.txt-b
then
	ok
else
	ko
fi
# restore setup
cp autoboot.txt-a /tmp/autoboot.txt
echo

# get-current
#
# To get the current running slot, the handler must be called with the argument
# get-current. The handler must output the current running slot’s bootname on
# the stdout, and return 0 on exit, if no error occurred. Implementing this is
# only needed when the /proc/cmdline is not providing information about current
# booted slot.

run "get-current fails if undefined slot is booted"
if ! bootloader-custom-backend get-current
then
	ok
else
	ko
fi
echo

run "get-current reports the primary slot if primary slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=2 \
   bootloader-custom-backend get-current | tee /dev/stderr | grep -q '^2$'
then
	ok
else
	ko
fi
echo

run "get-current reports the other slot if other slot is booted"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   bootloader-custom-backend get-current | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo

run "get-current reports the other slot if other slot is booted and the tryboot flag is set"
if FDTGET_CHOSEN_BOOTLOADER_PARTITION=3 \
   FDTGET_CHOSEN_BOOTLOADER_TRYBOOT=1 \
   bootloader-custom-backend get-current | tee /dev/stderr | grep -q '^3$'
then
	ok
else
	ko
fi
echo
