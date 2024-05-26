#
# Copyright 2024 Gaël PORTAY
#           2024 Rtone
#
# SPDX-License-Identifier: LGPL-2.1-or-later
#

PREFIX ?= /usr/local

.PHONY: all
all: check

.PHONY: install
install:
	install -D -m 755 bootloader-custom-backend $(DESTDIR)$(PREFIX)/lib/raspberrypi-firmware-rauc-bootloader-backend/bootloader-custom-backend
	install -D -m 755 rauc-mark-good.service $(DESTDIR)$(PREFIX)/lib/systemd/system/rauc-mark-good.service

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/lib/systemd/system/rauc-mark-good.service
	rm -f $(DESTDIR)$(PREFIX)/lib/raspberrypi-firmware-rauc-bootloader-backend/bootloader-custom/backend

.PHONY: check
check: bootloader-custom-backend
	shellcheck $^
