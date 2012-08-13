#ifndef _POLLER_H_
#define _POLLER_H_
#ifdef _WIN32
#include <winsock2.h>
typedef SOCKET socket_t;
#else
typedef int socket_t;
#endif

#include "zmq.h"

struct ZMQ_Poller {
	zmq_pollitem_t *items;
	int    next;
	int    count;
	int    free_list;
	int    len;
};

typedef struct ZMQ_Socket ZMQ_Socket;
typedef struct ZMQ_Poller ZMQ_Poller;


void poller_init           (ZMQ_Poller *poller, int length);
void poller_cleanup        (ZMQ_Poller *poller);
int  poller_find_sock_item (ZMQ_Poller *poller, ZMQ_Socket *sock);
int  poller_find_fd_item   (ZMQ_Poller *poller, socket_t fd);
void poller_remove_item    (ZMQ_Poller *poller, int idx);
int  poller_get_free_item  (ZMQ_Poller *poller);
int  poller_poll           (ZMQ_Poller *poller, long timeout);
int  poller_next_revents   (ZMQ_Poller *poller, int *revents);

#endif
