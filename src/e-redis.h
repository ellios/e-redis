/*
 * e-redis.h
 *
 *  Created on: 2012-5-24
 *      Author: ellios
 */

#ifndef E_REDIS_H_
#define E_REDIS_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <stdarg.h>

#include "ae.h"
#include "anet.h"
#include "adlist.h"


/* Error codes */
#define REDIS_OK                0
#define REDIS_ERR               -1

/* Static server configuration */
#define REDIS_SERVERPORT        6379    /* TCP port */
#define REDIS_MAX_LOGMSG_LEN    4096 /* Default maximum length of syslog messages */


/* Log levels */
#define REDIS_DEBUG 0
#define REDIS_VERBOSE 1
#define REDIS_NOTICE 2
#define REDIS_WARNING 3

/* Anti-warning macro... */
#define REDIS_NOTUSED(V) ((void) V)


/* Global server state structure */
typedef struct eredisServer {
    pthread_t mainthread;
    int arch_bits;
    int port;
    char *bindaddr;
    char *unixsocket;
    mode_t unixsocketperm;
    int ipfd;
    int sofd;

    list *clients;

    char neterr[ANET_ERR_LEN];
    aeEventLoop *el;

    int stat_numconnections;
}redisServer;

typedef struct eredisClient{
    int fd;
}redisClient;


/*-----------------------------------------------------------------------------
 * Extern declarations
 *----------------------------------------------------------------------------*/

extern redisServer server;


redisClient *createClient(int fd);
void acceptHandler(aeEventLoop *el, int fd, void *privdata, int mask);
void acceptTcpHandler(aeEventLoop *el, int fd, void *privdata, int mask);


#endif /* E_REDIS_H_ */
