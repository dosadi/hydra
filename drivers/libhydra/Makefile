CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -I../linux/uapi

all: libhydra.a

libhydra.a: hydra.o
	ar rcs $@ $^

hydra.o: hydra.c hydra.h

clean:
	rm -f hydra.o libhydra.a

.PHONY: all clean
