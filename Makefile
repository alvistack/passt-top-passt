CFLAGS += -Wall -Wextra -pedantic
CFLAGS += -DRLIMIT_STACK_VAL=$(shell ulimit -s)

prefix ?= /usr/local

all: passt pasta passt4netns qrap

avx2: CFLAGS += -Ofast -mavx2 -ftree-vectorize -funroll-loops
avx2: clean all

static: CFLAGS += -static
static: clean all

passt: passt.c passt.h arp.c arp.h checksum.c checksum.h conf.c conf.h \
	dhcp.c dhcp.h dhcpv6.c dhcpv6.h pcap.c pcap.h ndp.c ndp.h \
	siphash.c siphash.h tap.c tap.h icmp.c icmp.h tcp.c tcp.h \
	udp.c udp.h util.c util.h
	$(CC) $(CFLAGS) passt.c arp.c checksum.c conf.c dhcp.c dhcpv6.c \
		pcap.c ndp.c siphash.c tap.c icmp.c tcp.c udp.c util.c -o passt

pasta: passt
	ln -s passt pasta
	ln -s passt.1 pasta.1

passt4netns: passt
	ln -s passt passt4netns

qrap: qrap.c passt.h
	$(CC) $(CFLAGS) -DARCH=\"$(shell uname -m)\" qrap.c -o qrap

.PHONY: clean
clean:
	-${RM} passt *.o qrap pasta pasta.1 passt4netns

install: passt pasta qrap
	cp -d passt pasta qrap $(prefix)/bin
	cp -d passt.1 pasta.1 qrap.1 $(prefix)/man/man1

uninstall:
	-${RM} $(prefix)/bin/passt
	-${RM} $(prefix)/bin/pasta
	-${RM} $(prefix)/bin/qrap
	-${RM} $(prefix)/man/man1/passt.1
	-${RM} $(prefix)/man/man1/pasta.1
	-${RM} $(prefix)/man/man1/qrap.1
