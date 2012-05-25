#include "e-redis.h"
#include <sys/uio.h>

static void acceptCommonHandler(int fd) {
    redisClient *c;
    if ((c = createClient(fd)) == NULL) {
        redisLog(REDIS_WARNING,"Error allocating resoures for the client");
        close(fd); /* May be already closed, just ingore errors */
        return;
    }
    /* If maxclient directive is set and this is one client more... close the
     * connection. Note that we create the client instead to check before
     * for this condition, since now the socket is already set in nonblocking
     * mode and we can send an error for free using the Kernel I/O */
//    if (server.maxclients && listLength(server.clients) > server.maxclients) {
//        char *err = "-ERR max number of clients reached\r\n";
//
//        /* That's a best effort error message, don't check write errors */
//        if (write(c->fd,err,strlen(err)) == -1) {
//            /* Nothing to do, Just to avoid the warning... */
//        }
//        freeClient(c);
//        return;
//    }
    char *str = "accept connect";
    write(c->fd, str, strlen(str));
    server.stat_numconnections++;
}

redisClient *createClient(int fd) {
    redisClient *c = zmalloc(sizeof(redisClient));
    c->fd = fd;
    return c;
}

void acceptTcpHandler(aeEventLoop *el, int fd, void *privdata, int mask) {
    int cport, cfd;
    char cip[128];
    REDIS_NOTUSED(el);
    REDIS_NOTUSED(mask);
    REDIS_NOTUSED(privdata);

    cfd = anetTcpAccept(server.neterr, fd, cip, &cport);
    if (cfd == AE_ERR) {
        redisLog(REDIS_WARNING,"Accepting client connection: %s", server.neterr);
        return;
    }
    redisLog(REDIS_VERBOSE,"Accepted %s:%d", cip, cport);
    acceptCommonHandler(cfd);
}



