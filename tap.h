/* SPDX-License-Identifier: AGPL-3.0-or-later
 * Copyright (c) 2021 Red Hat GmbH
 * Author: Stefano Brivio <sbrivio@redhat.com>
 */

#ifndef TAP_H
#define TAP_H

void tap_ip_send(const struct ctx *c, const struct in6_addr *src, uint8_t proto,
		 const char *in, size_t len, uint32_t flow);
int tap_send(const struct ctx *c, const void *data, size_t len, int vnet_pre);
void tap_handler(struct ctx *c, int fd, uint32_t events,
		 const struct timespec *now);
void tap_sock_init(struct ctx *c);

#endif /* TAP_H */
