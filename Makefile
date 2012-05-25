# Redis Makefile
# Copyright (C) 2009 Salvatore Sanfilippo <antirez at gmail dot com>
# This file is released under the BSD license, see the COPYING file

release_hdr := $(shell sh -c './mkreleasehdr.sh')
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
OPTIMIZATION?=-O2

CCCOLOR="\033[34m"
LINKCOLOR="\033[34;1m"
SRCCOLOR="\033[33m"
BINCOLOR="\033[37;1m"
MAKECOLOR="\033[32;1m"
ENDCOLOR="\033[0m"

ifndef V
QUIET_CC = @printf '    %b %b\n' $(CCCOLOR)CC$(ENDCOLOR) $(SRCCOLOR)$@$(ENDCOLOR);
QUIET_LINK = @printf '    %b %b\n' $(LINKCOLOR)LINK$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR);
endif

ifeq ($(uname_S),Linux)
  ifneq ($(FORCE_LIBC_MALLOC),yes)
    USE_JEMALLOC=yes
  endif
endif

ifeq ($(uname_S),SunOS)
  CFLAGS?=-std=c99 -pedantic $(OPTIMIZATION) -Wall -W -D__EXTENSIONS__ -D_XPG6
  CCLINK?=-ldl -lnsl -lsocket -lm -lpthread
  DEBUG?=-g -ggdb
else
  CFLAGS?=-std=c99 -pedantic $(OPTIMIZATION) -Wall -W $(ARCH) $(PROF)
  CCLINK?=-lm -pthread
  DEBUG?=-g -rdynamic -ggdb
endif

ifeq ($(USE_TCMALLOC),yes)
  ALLOC_DEP=
  ALLOC_LINK=-ltcmalloc
  ALLOC_FLAGS=-DUSE_TCMALLOC
endif

ifeq ($(USE_TCMALLOC_MINIMAL),yes)
  ALLOC_DEP=
  ALLOC_LINK=-ltcmalloc_minimal
  ALLOC_FLAGS=-DUSE_TCMALLOC
endif

ifeq ($(USE_JEMALLOC),yes)
  ALLOC_DEP=../deps/jemalloc/lib/libjemalloc.a
  ALLOC_LINK=$(ALLOC_DEP) -ldl
  ALLOC_FLAGS=-DUSE_JEMALLOC -I../deps/jemalloc/include
endif

CCOPT= $(CFLAGS) $(ARCH) $(PROF)

PREFIX= /usr/local
INSTALL_BIN= $(PREFIX)/bin
INSTALL= cp -p

OBJ = adlist.o ae.o anet.o dict.o redis.o sds.o zmalloc.o lzf_c.o lzf_d.o pqsort.o zipmap.o sha1.o ziplist.o release.o networking.o util.o object.o db.o replication.o rdb.o t_string.o t_list.o t_set.o t_zset.o t_hash.o config.o aof.o vm.o pubsub.o multi.o debug.o sort.o intset.o syncio.o slowlog.o bio.o
BENCHOBJ = ae.o anet.o redis-benchmark.o sds.o adlist.o zmalloc.o
CLIOBJ = anet.o sds.o adlist.o redis-cli.o zmalloc.o release.o
CHECKDUMPOBJ = redis-check-dump.o lzf_c.o lzf_d.o
CHECKAOFOBJ = redis-check-aof.o

PRGNAME = redis-server
BENCHPRGNAME = redis-benchmark
CLIPRGNAME = redis-cli
CHECKDUMPPRGNAME = redis-check-dump
CHECKAOFPRGNAME = redis-check-aof

all: redis-benchmark redis-cli redis-check-dump redis-check-aof redis-server
	@echo ""
	@echo "Hint: To run 'make test' is a good idea ;)"
	@echo ""

# Deps (use make dep to generate this)
adlist.o: adlist.c adlist.h zmalloc.h
ae.o: ae.c ae.h zmalloc.h config.h ae_kqueue.c
ae_epoll.o: ae_epoll.c
ae_kqueue.o: ae_kqueue.c
ae_select.o: ae_select.c
anet.o: anet.c fmacros.h anet.h
aof.o: aof.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
bio.o: bio.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h bio.h
config.o: config.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
db.o: db.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
debug.o: debug.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h sha1.h
dict.o: dict.c fmacros.h dict.h zmalloc.h
endian.o: endian.c
intset.o: intset.c intset.h zmalloc.h endian.h
lzf_c.o: lzf_c.c lzfP.h
lzf_d.o: lzf_d.c lzfP.h
multi.o: multi.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
networking.o: networking.c redis.h fmacros.h config.h ae.h sds.h dict.h \
  adlist.h zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
object.o: object.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
pqsort.o: pqsort.c
pubsub.o: pubsub.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
rdb.o: rdb.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h lzf.h
redis-benchmark.o: redis-benchmark.c fmacros.h ae.h \
  ../deps/hiredis/hiredis.h sds.h adlist.h zmalloc.h
redis-check-aof.o: redis-check-aof.c fmacros.h config.h
redis-check-dump.o: redis-check-dump.c lzf.h
redis-cli.o: redis-cli.c fmacros.h version.h ../deps/hiredis/hiredis.h \
  sds.h zmalloc.h ../deps/linenoise/linenoise.h help.h
redis.o: redis.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h slowlog.h \
  bio.h
release.o: release.c release.h
replication.o: replication.c redis.h fmacros.h config.h ae.h sds.h dict.h \
  adlist.h zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
sds.o: sds.c sds.h zmalloc.h
sha1.o: sha1.c sha1.h
slowlog.o: slowlog.c redis.h fmacros.h config.h ae.h sds.h dict.h \
  adlist.h zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h \
  slowlog.h
sort.o: sort.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h pqsort.h
syncio.o: syncio.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
t_hash.o: t_hash.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
t_list.o: t_list.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
t_set.o: t_set.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
t_string.o: t_string.c redis.h fmacros.h config.h ae.h sds.h dict.h \
  adlist.h zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
t_zset.o: t_zset.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
util.o: util.c fmacros.h util.h
vm.o: vm.c redis.h fmacros.h config.h ae.h sds.h dict.h adlist.h \
  zmalloc.h anet.h zipmap.h ziplist.h intset.h version.h util.h
ziplist.o: ziplist.c zmalloc.h util.h ziplist.h endian.h
zipmap.o: zipmap.c zmalloc.h endian.h
zmalloc.o: zmalloc.c config.h zmalloc.h

.PHONY: dependencies

dependencies:
	@printf '%b %b\n' $(MAKECOLOR)MAKE$(ENDCOLOR) $(BINCOLOR)hiredis$(ENDCOLOR)
	@cd ../deps/hiredis && $(MAKE) static ARCH="$(ARCH)"
	@printf '%b %b\n' $(MAKECOLOR)MAKE$(ENDCOLOR) $(BINCOLOR)linenoise$(ENDCOLOR)
	@cd ../deps/linenoise && $(MAKE) ARCH="$(ARCH)"

../deps/jemalloc/lib/libjemalloc.a:
	@printf '%b %b\n' $(MAKECOLOR)MAKE$(ENDCOLOR) $(BINCOLOR)jemalloc$(ENDCOLOR)
	@cd ../deps/jemalloc && ./configure $(JEMALLOC_CFLAGS) --with-jemalloc-prefix=je_ --enable-cc-silence && $(MAKE) lib/libjemalloc.a

redis-benchmark.o:
	$(QUIET_CC)$(CC) -c $(CFLAGS) -I../deps/hiredis $(DEBUG) $(COMPILE_TIME) $<

redis-benchmark: dependencies $(BENCHOBJ)
	@printf '%b %b\n' $(MAKECOLOR)MAKE$(ENDCOLOR) $(BINCOLOR)hiredis$(ENDCOLOR)
	@cd ../deps/hiredis && $(MAKE) static ARCH="$(ARCH)"
	$(QUIET_LINK)$(CC) -o $(BENCHPRGNAME) $(CCOPT) $(DEBUG) $(BENCHOBJ) ../deps/hiredis/libhiredis.a $(CCLINK) $(ALLOC_LINK)

redis-cli.o:
	$(QUIET_CC)$(CC) -c $(CFLAGS) -I../deps/hiredis -I../deps/linenoise $(DEBUG) $(COMPILE_TIME) $<

redis-cli: dependencies $(CLIOBJ)
	$(QUIET_LINK)$(CC) -o $(CLIPRGNAME) $(CCOPT) $(DEBUG) $(CLIOBJ) ../deps/hiredis/libhiredis.a ../deps/linenoise/linenoise.o $(CCLINK) $(ALLOC_LINK)

redis-check-dump.o:
	$(QUIET_CC)$(CC) -c $(CFLAGS) $(DEBUG) $(COMPILE_TIME) $<

redis-check-dump: $(CHECKDUMPOBJ)
	$(QUIET_LINK)$(CC) -o $(CHECKDUMPPRGNAME) $(CCOPT) $(DEBUG) $(CHECKDUMPOBJ) $(CCLINK)

redis-check-aof.o:
	$(QUIET_CC)$(CC) -c $(CFLAGS) $(DEBUG) $(COMPILE_TIME) $<

redis-check-aof: $(CHECKAOFOBJ)
	$(QUIET_LINK)$(CC) -o $(CHECKAOFPRGNAME) $(CCOPT) $(DEBUG) $(CHECKAOFOBJ) $(CCLINK)

redis-server: $(OBJ)
	$(QUIET_LINK)$(CC) -o $(PRGNAME) $(CCOPT) $(DEBUG) $(OBJ) $(CCLINK) $(ALLOC_LINK)

# Because the jemalloc.h header is generated as a part of the jemalloc build
# process, building it should complete before building any other object.
%.o: %.c $(ALLOC_DEP)
	$(QUIET_CC)$(CC) -c $(CFLAGS) $(ALLOC_FLAGS) $(DEBUG) $(COMPILE_TIME) $<

clean:
	rm -rf $(PRGNAME) $(BENCHPRGNAME) $(CLIPRGNAME) $(CHECKDUMPPRGNAME) $(CHECKAOFPRGNAME) *.o *.gcda *.gcno *.gcov

dep:
	$(CC) -MM *.c -I ../deps/hiredis -I ../deps/linenoise

test: redis-server redis-check-aof
	@(cd ..; ./runtest)

bench:
	./redis-benchmark

log:
	git log '--pretty=format:%ad %s (%cn)' --date=short > ../Changelog

32bit:
	@echo ""
	@echo "WARNING: if it fails under Linux you probably need to install libc6-dev-i386"
	@echo ""
	$(MAKE) ARCH="-m32" JEMALLOC_CFLAGS='CFLAGS="-std=gnu99 -Wall -pipe -g3 -fvisibility=hidden -O3 -funroll-loops -m32"'

gprof:
	$(MAKE) PROF="-pg"

gcov:
	$(MAKE) PROF="-fprofile-arcs -ftest-coverage"

noopt:
	$(MAKE) OPTIMIZATION=""

32bitgprof:
	$(MAKE) PROF="-pg" ARCH="-arch i386"

install: all
	mkdir -p $(INSTALL_BIN)
	$(INSTALL) $(PRGNAME) $(INSTALL_BIN)
	$(INSTALL) $(BENCHPRGNAME) $(INSTALL_BIN)
	$(INSTALL) $(CLIPRGNAME) $(INSTALL_BIN)
	$(INSTALL) $(CHECKDUMPPRGNAME) $(INSTALL_BIN)
	$(INSTALL) $(CHECKAOFPRGNAME) $(INSTALL_BIN)
