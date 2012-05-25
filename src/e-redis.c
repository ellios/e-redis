/*
 * e-redis.c
 *
 *  Created on: 2012-5-24
 *      Author: ellios
 */
#include <unistd.h>

#include "e-redis.h"
#include "ae.h"

redisServer server;

void redisLog(int level, const char *fmt, ...) {
	const char *c = ".-*#";
	time_t now = time(NULL);
	va_list ap;
	FILE *fp;
	char buf[64];
	char msg[REDIS_MAX_LOGMSG_LEN];

	fp = stdout;
	if (!fp)
		return;

	va_start(ap, fmt);
	vsnprintf(msg, sizeof(msg), fmt, ap);
	va_end(ap);

	strftime(buf, sizeof(buf), "%d %b %H:%M:%S", localtime(&now));
	fprintf(fp, "[%d] %s %c %s\n", (int) getpid(), buf, c[level], msg);
	fflush(fp);
}

void oom(const char *msg) {
    redisLog(REDIS_WARNING, "%s: Out of memory\n",msg);
    sleep(1);
    abort();
}

int serverCron(struct aeEventLoop *eventLoop, long long id, void *clientData){
	time_t t = time(NULL);
	printf("serverCron. time : %ld\n", t);
	return 100;
}

void initServerConfig(){
    server.arch_bits = (sizeof(long) == 8) ? 64 : 32;
    server.port = REDIS_SERVERPORT;
    server.bindaddr = NULL;
    server.unixsocket = NULL;
    server.unixsocketperm = 0;
    server.ipfd = -1;
    server.sofd = -1;
    server.stat_numconnections = 0;
}

void initServer(){

    server.mainthread = pthread_self();
    server.clients = listCreate();
    server.el = aeCreateEventLoop();

    if (server.port != 0) {
        server.ipfd = anetTcpServer(server.neterr,server.port,server.bindaddr);
        if (server.ipfd == ANET_ERR) {
            redisLog(REDIS_WARNING, "Opening port %d: %s",
                server.port, server.neterr);
            exit(1);
        }
    }
//    if (server.unixsocket != NULL) {
//        unlink(server.unixsocket); /* don't care if this fails */
//        server.sofd = anetUnixServer(server.neterr,server.unixsocket,server.unixsocketperm);
//        if (server.sofd == ANET_ERR) {
//            redisLog(REDIS_WARNING, "Opening socket: %s", server.neterr);
//            exit(1);
//        }
//    }
    if (server.ipfd < 0 && server.sofd < 0) {
        redisLog(REDIS_WARNING, "Configured to not listen anywhere, exiting.");
        exit(1);
    }

    aeCreateTimeEvent(server.el, 1, serverCron, NULL, NULL);
    if (server.ipfd > 0 && aeCreateFileEvent(server.el,server.ipfd,AE_READABLE,
        acceptTcpHandler,NULL) == AE_ERR) oom("creating file event");
//    if (server.sofd > 0 && aeCreateFileEvent(server.el,server.sofd,AE_READABLE,
//        acceptUnixHandler,NULL) == AE_ERR) oom("creating file event");
}

/* This function gets called every time Redis is entering the
 * main loop of the event driven library, that is, before to sleep
 * for ready file descriptors. */
void beforeSleep(struct aeEventLoop *eventLoop) {
	printf("do beforeSleep work!\n");
}

int main(int argv, char *argc){
	initServerConfig();
	initServer();

    if (server.ipfd > 0)
        redisLog(REDIS_NOTICE,"The server is now ready to accept connections on port %d", server.port);
    if (server.sofd > 0)
        redisLog(REDIS_NOTICE,"The server is now ready to accept connections at %s", server.unixsocket);
//    aeSetBeforeSleepProc(server.el,beforeSleep);
    aeMain(server.el);
    aeDeleteEventLoop(server.el);

	return EXIT_SUCCESS;
}


