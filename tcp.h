/* SPDX-License-Identifier: GPL-2.0-or-later
 * Copyright (c) 2021 Red Hat GmbH
 * Author: Stefano Brivio <sbrivio@redhat.com>
 */

#ifndef TCP_H
#define TCP_H

#define TCP_TIMER_INTERVAL		1000	/* ms */

#define TCP_CONN_INDEX_BITS		17	/* 128k - 1 */
#define TCP_MAX_CONNS			MAX_FROM_BITS(TCP_CONN_INDEX_BITS)

struct ctx;

void tcp_timer_handler(struct ctx *c, union epoll_ref ref);
void tcp_listen_handler(struct ctx *c, union epoll_ref ref,
			const struct timespec *now);
void tcp_sock_handler(struct ctx *c, union epoll_ref ref, uint32_t events);
int tcp_tap_handler(struct ctx *c, int af, const void *saddr, const void *daddr,
		    const struct pool *p, const struct timespec *now);
int tcp_sock_init(const struct ctx *c, sa_family_t af, const void *addr,
		  const char *ifname, in_port_t port);
int tcp_init(struct ctx *c);
void tcp_timer(struct ctx *c, const struct timespec *ts);
void tcp_defer_handler(struct ctx *c);

void tcp_sock_set_bufsize(const struct ctx *c, int s);
void tcp_update_l2_buf(const unsigned char *eth_d, const unsigned char *eth_s);

/**
 * union tcp_epoll_ref - epoll reference portion for TCP connections
 * @index:		Index of connection in table
 * @u32:		Opaque u32 value of reference
 */
union tcp_epoll_ref {
	uint32_t index:20;
	uint32_t u32;
};

/**
 * union tcp_listen_epoll_ref - epoll reference portion for TCP listening
 * @port:	Port number we're forwarding *to* (listening port plus delta)
 * @ns:		True if listening within the pasta namespace
 * @u32:	Opaque u32 value of reference
 */
union tcp_listen_epoll_ref {
	struct {
		in_port_t	port;
		bool		ns;
	};
	uint32_t u32;
};

/**
 * struct tcp_ctx - Execution context for TCP routines
 * @hash_secret:	128-bit secret for hash functions, ISN and hash table
 * @conn_count:		Count of total connections in connection table
 * @port_to_tap:	Ports bound host-side, packets to tap or spliced
 * @fwd_in:		Port forwarding configuration for inbound packets
 * @fwd_out:		Port forwarding configuration for outbound packets
 * @timer_run:		Timestamp of most recent timer run
 * @kernel_snd_wnd:	Kernel reports sending window (with commit 8f7baad7f035)
 * @pipe_size:		Size of pipes for spliced connections
 */
struct tcp_ctx {
	uint64_t hash_secret[2];
	int conn_count;
	struct port_fwd fwd_in;
	struct port_fwd fwd_out;
	struct timespec timer_run;
#ifdef HAS_SND_WND
	int kernel_snd_wnd;
#endif
	size_t pipe_size;
};

#endif /* TCP_H */
