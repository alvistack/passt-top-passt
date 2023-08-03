/* SPDX-License-Identifier: GPL-2.0-or-later
 * Copyright (c) 2021 Red Hat GmbH
 * Author: Stefano Brivio <sbrivio@redhat.com>
 */

#ifndef NETLINK_H
#define NETLINK_H

extern int nl_sock;
extern int nl_sock_ns;

void nl_sock_init(const struct ctx *c, bool ns);
unsigned int nl_get_ext_if(int s, sa_family_t af);
int nl_route_get_def(int s, unsigned int ifi, sa_family_t af, void *gw);
int nl_route_set_def(int s, unsigned int ifi, sa_family_t af, void *gw);
void nl_route_dup(int s_src, unsigned int ifi_src,
		  int s_dst, unsigned int ifi_dst, sa_family_t af);
int nl_addr_get(int s, unsigned int ifi, sa_family_t af,
		void *addr, int *prefix_len, void *addr_l);
int nl_addr_set(int s, unsigned int ifi, sa_family_t af,
		void *addr, int prefix_len);
void nl_addr_dup(int s_src, unsigned int ifi_src,
		 int s_dst, unsigned int ifi_dst, sa_family_t af);
int nl_link_get_mac(int s, unsigned int ifi, void *mac);
int nl_link_set_mac(int s, unsigned int ifi, void *mac);
int nl_link_up(int s, unsigned int ifi, int mtu);

#endif /* NETLINK_H */
