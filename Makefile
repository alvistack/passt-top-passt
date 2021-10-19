# SPDX-License-Identifier: AGPL-3.0-or-later
#
# PASST - Plug A Simple Socket Transport
#  for qemu/UNIX domain socket mode
#
# PASTA - Pack A Subtle Tap Abstraction
#  for network namespace/tap device mode
#
# Copyright (c) 2021 Red Hat GmbH
# Author: Stefano Brivio <sbrivio@redhat.com>

CFLAGS += -Wall -Wextra -pedantic
CFLAGS += -DRLIMIT_STACK_VAL=$(shell ulimit -s)
CFLAGS += -DPAGE_SIZE=$(shell getconf PAGE_SIZE)
CFLAGS += -DNETNS_RUN_DIR=\"/run/netns\"
CFLAGS += -DPASST_AUDIT_ARCH=AUDIT_ARCH_$(shell uname -m | tr [a-z] [A-Z])

# On gcc 11.2, with -O2 and -flto, tcp_hash() and siphash_20b(), if inlined,
# seem to be hitting something similar to:
#	https://gcc.gnu.org/bugzilla/show_bug.cgi?id=78993
# from the pointer arithmetic used from the tcp_tap_handler() path to get the
# remote connection address.
ifeq ($(shell $(CC) -dumpversion),11)
ifneq (,$(filter -flto%,$(CFLAGS)))
ifneq (,$(filter -O2,$(CFLAGS)))
	CFLAGS += -DTCP_HASH_NOINLINE
	CFLAGS += -DSIPHASH_20B_NOINLINE
endif
endif
endif

prefix ?= /usr/local

all: passt pasta passt4netns qrap

avx2: CFLAGS += -Ofast -mavx2 -ftree-vectorize -funroll-loops
avx2: clean all

static: CFLAGS += -static -DGLIBC_NO_STATIC_NSS
static: clean all

seccomp.h: *.c $(filter-out seccomp.h,$(wildcard *.h))
	@ ./seccomp.sh

passt: $(filter-out qrap.c,$(wildcard *.c)) \
	$(filter-out qrap.h,$(wildcard *.h)) seccomp.h
	$(CC) $(CFLAGS) $(filter-out qrap.c,$(wildcard *.c)) -o passt

pasta: passt
	ln -s passt pasta
	ln -s passt.1 pasta.1

passt4netns: passt
	ln -s passt passt4netns

qrap: qrap.c passt.h
	$(CC) $(CFLAGS) -DARCH=\"$(shell uname -m)\" \
		qrap.c -o qrap

.PHONY: clean
clean:
	-${RM} passt *.o seccomp.h qrap pasta pasta.1 passt4netns \
		passt.tar passt.tar.gz *.deb *.rpm

install: passt pasta qrap
	mkdir -p $(DESTDIR)$(prefix)/bin $(DESTDIR)$(prefix)/share/man/man1
	cp -d passt pasta qrap $(DESTDIR)$(prefix)/bin
	cp -d passt.1 pasta.1 qrap.1 $(DESTDIR)$(prefix)/share/man/man1

uninstall:
	-${RM} $(DESTDIR)$(prefix)/bin/passt
	-${RM} $(DESTDIR)$(prefix)/bin/pasta
	-${RM} $(DESTDIR)$(prefix)/bin/qrap
	-${RM} $(DESTDIR)$(prefix)/share/man/man1/passt.1
	-${RM} $(DESTDIR)$(prefix)/share/man/man1/pasta.1
	-${RM} $(DESTDIR)$(prefix)/share/man/man1/qrap.1

pkgs:
	tar cf passt.tar -P --xform 's//\/usr\/bin\//' passt pasta qrap
	tar rf passt.tar -P --xform 's//\/usr\/share\/man\/man1\//' \
		passt.1 pasta.1 qrap.1
	gzip passt.tar
	EMAIL="sbrivio@redhat.com" fakeroot alien --to-deb \
		--description="User-mode networking for VMs and namespaces" \
		-k --version=$(shell git rev-parse --short HEAD) \
		passt.tar.gz
	fakeroot alien --to-rpm --target=$(shell uname -m) \
		--description="User-mode networking for VMs and namespaces" \
		-k --version=g$(shell git rev-parse --short HEAD) passt.tar.gz
